local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local position = require("speedtyper.position")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local sounds = require("speedtyper.sounds")
local logger = require("speedtyper.logger")

---@class SpeedTyperGameMode
---@field protected closing boolean
---@field protected timer uv_timer_t
---@field protected extm_ids integer[]
---@field protected info_extm_id integer
---@field protected text string[]
---@field protected time_sec number
---@field protected word_count integer
---@field protected number_of_words integer
---@field protected text_generator SpeedTyperText
---@field protected stats SpeedTyperStats
---@field protected pace_cursor SpeedTyperPaceCursor
---@field protected ignore_next_change  boolean
local GM = {}

---@return SpeedTyperGameMode
function GM:new()
    local o = {
        closing = false,
        timer = nil,
        extm_ids = {},
        info_extm_id = nil,
        time_sec = 0,
        word_count = 0,
        text_generator = require("speedtyper.text"),
        stats = require("speedtyper.stats"),
        ignore_next_change = true,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function GM:start()
    self:reset_values()
    vim.schedule(function()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
    end)
    self:set_extmarks()
    util.set_cursor_pos(constants.text_first_line + 1, 0, globals.winnr)
    vim.keymap.set("i", "<cr>", "<nop>", { buffer = globals.bufnr })

    self:after_start()
end

function GM:stop()
    self.closing = true
    if self.pace_cursor then
        self.pace_cursor:stop()
        self.pace_cursor = nil
    end
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    pcall(util.unset_keymaps, settings.keymaps.start_game, globals.bufnr)

    logger:log("countdown game mode stopped")
end

-- luacheck: push ignore self

---@protected
---child classes should override this function
function GM:after_start() end

-- luacheck: pop

---@protected
function GM:attach_to_speedtyper_buffer()
    logger:log("attaching to the speedtyper buffer")
    api.nvim_buf_attach(globals.bufnr, false, {
        on_bytes = function(...)
            if self.closing then
                logger:log("custom mode on_bytes detached")
                -- return true to detach from buffer
                return true
            end

            if self.ignore_next_change then
                self.ignore_next_change = false
                return
            end

            local ev = { ... }
            ---@type on_bytes_args
            local args = {
                type = ev[1],
                buf_handle = ev[2],
                changetick = ev[3],
                start_row = ev[4],
                start_column = ev[5],
                byte_offset = ev[6],
                old_end_row = ev[7],
                old_end_column = ev[8],
                old_end_byte_len = ev[9],
                new_end_row = ev[10],
                new_end_column = ev[11],
                new_end_byte_len = ev[12],
            }

            vim.schedule(function()
                self:handle_typing(args)
                ---@type SpeedTyperCharInfo
                local last_typed = self.stats.text_info:peek()
                if last_typed ~= nil then
                    sounds:play_sound(last_typed:is_typo())
                end
            end)
        end,
    })
end

-- luacheck: push ignore self

---@protected
---child classes should override this function
function GM:reset_values() end

-- luacheck: pop

---@protected
function GM:set_extmarks()
    self.extm_ids = {}
    local n = math.min(constants.text_num_lines, #self.text)
    for i = 1, n do
        local line = constants.text_first_line + i - 1
        local extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, line, 0, {
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
            priority = 50,
        })
        table.insert(self.extm_ids, extm_id)
    end
end

---@protected
function GM:update_extmarks()
    if #self.extm_ids == 0 then
        return
    end
    for i, extm_id in ipairs(self.extm_ids) do
        local row = constants.text_first_line + i - 1
        local line = api.nvim_buf_get_lines(globals.bufnr, row, row + 1, false)[1]
        local col = api.nvim_strwidth(line)
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, row, col, {
            virt_text = { { util.utf_sub(self.text[i], col + 1), "SpeedTyperTextUntyped" } },
            virt_text_win_col = col,
            id = extm_id,
            priority = 50,
        })
    end
end

---TODO: refactor this function, should be easier to do it now that we found nvim_buf_attach
---Edge cases:
---[ ] prevent user from going above the first line via `<bspace>`, `<c-u>`, `<c-w>`, etc. (less important)
---[x] jump to next line without user pressing `<cr>`
---[x] jump to prev line when user presses `<bspace>` at the beginning of the line
---[x] when finishing the middle line, move text up and move the cursor to the beginning of the middle line
---[x] check if we reached the end of the text
---[x] respect stop_on_error
---[x] respect strict_space
---[x] use api.nvim_strwidth(str) instead of #str
---[x] if we're on the last line of text, remove the unnecessary extmarks
---[x] display stats after stopping the game
---[x] update the live progress
---[x] put more meaningful logs
---FIX:
---[x] jumping to the next line with `<space>` when `strict_space` is `off`
---[x] last line extmark is not removed when needed
---[x] last character of the last line is not colored correctly
---[x] choose when to use `col` and when to use `last_typed_line_len`

---@protected
---@param args on_bytes_args
function GM:handle_typing(args)
    -- NOTE: row, col, prev_row, prev_col are zero-indexed positions in the vim's grid (or whatever it's called)
    -- so we'll be adding 1 to them to make them one-indexed because some of the functions we use require one-indexed values

    local row = args.start_row + args.new_end_row
    local col = args.new_end_row == 0 and (args.start_column + args.new_end_column)
        or args.new_end_column

    local prev_row = args.start_row + args.old_end_row
    local prev_col = args.old_end_row == 0 and (args.start_column + args.old_end_column)
        or args.old_end_column

    ---index of the current line in the text table
    local idx = row - constants.text_first_line + 1
    if idx < 1 or idx > #self.text then
        return
    end

    -- if there's a typo, block all input except for `<bspace>`, `<c-u>`, `<c-w>`, etc.

    if
        settings:get_selected("stop_on_error")
        and not self.moved_back(row, col, prev_row, prev_col)
    then
        -- only call get_typos when we're sure that we need to, so we don't
        -- unnecessarily waste time
        if #self.stats:get_typos() > 0 then
            util.set_cursor_pos(prev_row + 1, prev_col + 1, globals.winnr)
            self.ignore_next_change = true
            api.nvim_buf_set_text(globals.bufnr, prev_row, prev_col, row, col, {})

            logger:log("typing blocked due to `get_typos`")

            return
        end
    end

    ---the last line of the typed text (could be the line currently being typed or the line above it)
    ---@type string
    local last_typed_line = api.nvim_buf_get_lines(globals.bufnr, prev_row, prev_row + 1, false)[1]
    -- in case the user just finished typing the line and cursor moved to the next line (or same line if we're on the middle line)
    -- or the user moved to the previous line via `<bspace>`, `<c-u>`, `<c-w>`, etc.
    if #last_typed_line == 0 then
        last_typed_line = api.nvim_buf_get_lines(globals.bufnr, row, row + 1, false)[1]
    end
    ---@type integer
    local last_typed_line_len = api.nvim_strwidth(last_typed_line)

    -- check if the user has pressed some of the following keys: `<bspace>`, `<c-u>`, `<c-w>`, etc.
    if self.moved_back(row, col, prev_row, prev_col) then
        ---@type SpeedTyperCharInfo
        local deleted_char = self.stats.text_info:peek()
        if deleted_char.should_be == " " then
            self.word_count = self.word_count - 1
        end
        self.stats.text_info:pop()

        logger:log("deleted character:", deleted_char.should_be, deleted_char.typed)

        -- moved back to previous line via `<bspace>`, `<c-u>`, `<c-w>`, etc.
        if prev_col == 0 then
            -- if we jumped from the beginning of the line to the previous line, then we only need to pop the last character of the previous line
            -- (since there is no key kombination that can delete further back)

            self.ignore_next_change = true
            -- add empty line below cursor (because the user deleted it via `<bspace>`)
            api.nvim_buf_set_lines(globals.bufnr, row + 1, row + 1, false, { "" })

            self.ignore_next_change = true
            -- remove the last character, because user pressed `<bspace>` but neovim deleted the line, and not the last character of the previous line
            -- which mean the user will have to press `<bspace>` again to delete the last character
            api.nvim_buf_set_lines(
                globals.bufnr,
                row,
                row + 1,
                false,
                { util.utf_sub(last_typed_line, 1, -2) }
            )

            self.stats:redraw_typos()

            logger:log("moved to previous line")
        end

        self:update_extmarks()
        return
    end

    -- check if the user typed the correct character
    local typed = util.utf_char_at(last_typed_line, -1)
    local should_be = util.utf_char_at(self.text[idx], last_typed_line_len)
    self.stats:check_curr_char(typed, should_be, prev_row, prev_col + 1)

    -- check if the user typed `<space>`, and apply strict_space setting if needed
    if
        typed == " "
        and should_be ~= " "
        and col > 0
        and not settings:get_selected("strict_space")
    then
        -- if the typed character is a space and it should not be a space, then jump to the
        -- next word (if possible) and fill the gaps with spaces

        local next_space = util.utf_find(self.text[idx], " ", last_typed_line_len)
        next_space = next_space == -1 and api.nvim_strwidth(self.text[idx]) or next_space

        self.ignore_next_change = true
        api.nvim_put({ (" "):rep(next_space - last_typed_line_len, "") }, "c", true, true)
        for i = last_typed_line_len, next_space do
            local next_should_be = util.utf_char_at(self.text[idx], i)
            self.stats:check_curr_char(" ", next_should_be, row, i)
            if next_should_be == " " then
                self.word_count = self.word_count + 1
            end
        end

        last_typed_line_len = next_space

        logger:log(("insert %d spaces"):format(next_space - last_typed_line_len))
    end

    -- update word count
    if should_be == " " then
        self.word_count = self.word_count + 1
    end

    -- reached the end of the line
    if last_typed_line_len == api.nvim_strwidth(self.text[idx]) then
        -- we have three cases:
        --   1) we reached the end of the typing test
        --   2) we reached the end of the middle line, and we have to jump to the beginning of the current line
        --   3) we reached the end of one of the lines above middle line, and we have to jump to the beginning of the next line

        local cursor_row = row + 1

        if idx == #self.text then
            self:update_live_progress()
            self:update_extmarks()
            self:stop()
            self.stats.time = self.time_sec
            self.stats:display_stats()

            logger:log("reached the end of the text")

            return
        end

        if row == constants.text_middle_line then
            self.ignore_next_change = true
            self:move_up()
            util.set_cursor_pos(cursor_row, 0, globals.winnr)

            logger:log("moved to the beginning of the middle line")
        else
            util.set_cursor_pos(cursor_row + 1, 0, globals.winnr)

            logger:log("moved to the beginning of the next line")
        end
        self:update_extmarks()
        return
    end

    -- no more edge cases, just update the extmarks
    self:update_extmarks()
end

---@protected
---checks if the cursor has moved backwards (e.g. with `<bspace>` or `<c-u>`)
---@param row integer
---@param col integer
---@param prev_row integer
---@param prev_col integer
---@return boolean
function GM.moved_back(row, col, prev_row, prev_col)
    return row < prev_row or (row == prev_row and col < prev_col)
end

---@protected
function GM:move_up()
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        constants.text_first_line,
        constants.text_first_line + constants.text_num_lines
    )
    util.remove_element(self.text, self.text[1])
    if #self.text < constants.text_num_lines then
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, self.extm_ids[#self.extm_ids])
        util.remove_element(self.extm_ids, self.extm_ids[#self.extm_ids])
        if self.number_of_words == -1 then
            local win_width = api.nvim_win_get_width(globals.winnr)
            table.insert(self.text, self.text_generator:generate_sentence(win_width))
        end
    end

    self:set_extmarks()

    local written_lines = api.nvim_buf_get_lines(
        globals.bufnr,
        constants.text_first_line,
        constants.text_middle_line + 1,
        false
    )
    util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    api.nvim_buf_set_lines(
        globals.bufnr,
        constants.text_first_line,
        constants.text_middle_line + 1,
        false,
        written_lines
    )

    -- change line/col for the typos from the first line to -1,
    -- so redraw_typos don't draw them, but stats can still count them
    -- and move typos from the second line to the first line

    ---@type SpeedTyperCharInfo[]
    local text_info = self.stats.text_info:get_table()
    for _, info in ipairs(text_info) do
        if info.pos.line == constants.text_first_line then
            info.pos = position.new(-1, -1)
        end
    end
    self.stats.text_info:clear()
    for _, info in ipairs(text_info) do
        if info.pos.line ~= -1 then
            info.pos:update(info.pos.line - 1, info.pos.col)
            self.stats.text_info:push(info)
        end
    end
    self.stats:redraw_typos()

    self.pace_cursor:move_up(vim.iter(self.text)
        :map(function(l)
            return #l
        end)
        :totable())
end

-- luacheck: push ignore self

---@protected
---child classes should override this function
---@return string
---@diagnostic disable-next-line: missing-return
function GM:live_progress_text() end

-- luacheck: pop

---@protected
function GM:update_live_progress()
    if not settings:get_selected("live_progress") then
        return
    end

    self.info_extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants.info_line, 0, {
            virt_text = {
                {
                    self:live_progress_text(),
                    "SpeedTyperCountNormal",
                },
            },
            id = self.info_extm_id,
            priority = 50,
        })
end

---------------------------- timer stuff ------------------------------------------

-- luacheck: push ignore self

---@protected
---child classes should override this function
function GM:start_timer() end

-- luacheck: pop

---@protected
function GM:create_timer()
    self.timer = vim.uv.new_timer()
    local keys = type(settings.keymaps.start_game) == "table"
            ---@diagnostic disable-next-line: param-type-mismatch
            and table.concat(settings.keymaps.start_game, "/")
        or settings.keymaps.start_game
    local extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants.info_line, 0, {
        virt_text = {
            {
                ("Press %s to start the game."):format(keys),
                "SpeedTyperTextOk",
            },
        },
        priority = 50,
    })
    util.set_keymaps(settings.keymaps.start_game, function()
        self:attach_to_speedtyper_buffer()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
        vim.cmd.startinsert()
        util.set_cursor_pos(constants.text_first_line + 1, 0, globals.winnr)
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, extm_id)
        vim.schedule(function()
            util.clear_buffer_text(constants.win_height, globals.bufnr)
            self:set_extmarks()
        end)
        self:start_timer()
        self.pace_cursor:run()
    end, { buffer = globals.bufnr, desc = "SpeedTyper: Start the game." })
end

return GM
