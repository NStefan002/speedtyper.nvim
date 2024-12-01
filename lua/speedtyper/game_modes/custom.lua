local api = vim.api
local util = require("speedtyper.util")
local pace_cursor = require("speedtyper.pace_cursor")
local constants = require("speedtyper.constants")
local position = require("speedtyper.position")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local sounds = require("speedtyper.sounds")
local logger = require("speedtyper.logger")

---@class SpeedTyperCustom
---@field private closing boolean
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field info_extm_id integer
---@field text string[]
---@field time_sec number
---@field word_count integer
---@field number_of_words integer
---@field text_generator SpeedTyperText
---@field stats SpeedTyperStats
---@field pace_cursor SpeedTyperPaceCursor
---@field ignore_next_change  boolean
local Custom = {}
Custom.__index = Custom

---@return SpeedTyperCustom
function Custom.new()
    local self = setmetatable({
        closing = false,
        timer = nil,
        extm_ids = {},
        info_extm_id = nil,
        text = { "Paste your text here." },
        time_sec = 0,
        word_count = 0,
        number_of_words = nil,
        text_generator = require("speedtyper.text"),
        stats = require("speedtyper.stats"),
        pace_cursor = nil,
        ignore_next_change = true,
    }, Custom)
    return self
end

function Custom:start()
    self:_reset_values()
    vim.schedule(function()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
    end)
    self:_set_extmarks()
    util.set_cursor_pos(constants.text_first_line + 1, 0, globals.winnr)
    vim.keymap.set("i", "<cr>", "<nop>", { buffer = globals.bufnr })

    logger:log("waiting for the user to paste the text")
    local on_lines_detach = false
    api.nvim_buf_attach(globals.bufnr, false, {
        on_lines = function(...)
            -- if the game is closing/user changes to different game mode, then return true to detach from the buffer
            if self.closing or on_lines_detach then
                logger:log("stop waiting for the user to paste the text")
                return true
            end
            on_lines_detach = true

            local ev = { ... }
            ---@type on_lines_args
            local args = {
                type = ev[1],
                buf_handle = ev[2],
                changetick = ev[3],
                line_start = ev[4],
                line_end = ev[5],
                range_end = ev[6],
                byte_count = ev[7],
                deleted_codepoints = ev[8],
                deleted_codeunits = ev[9],
            }

            vim.schedule(function()
                local line_start, line_end = args.line_start, args.range_end
                ---text that user pasted
                local text = table.concat(
                    api.nvim_buf_get_lines(globals.bufnr, line_start, line_end, false),
                    " "
                )
                local words = util.split(text, " ")
                self.text_generator:use_custom_words(words)
                local win_width = api.nvim_win_get_width(globals.winnr)
                self.text = self.text_generator:generate_n_words_text(win_width, #words)
                self.number_of_words = #words

                self.pace_cursor = pace_cursor.new(vim.iter(self.text)
                    :map(function(line)
                        return #line
                    end)
                    :totable())

                util.clear_buffer_text(constants.win_height, globals.bufnr)
                self:_set_extmarks()
                util.set_cursor_pos(constants.text_first_line + 1, 0, globals.winnr)
                api.nvim_set_option_value("modifiable", false, { buf = globals.bufnr })
                self:_create_timer()
            end)

            logger:log("text pasted")
            -- return true to detach from the buffer
            return true
        end,
    })

    logger:log("custom game mode started")
end

function Custom:_attach_to_speedtyper_buffer()
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
                self:_handle_typing(args)
                ---@type SpeedTyperCharInfo
                local last_typed = self.stats.text_info:peek()
                if last_typed ~= nil then
                    sounds:play_sound(last_typed:is_typo())
                end
            end)
        end,
    })
end

function Custom:stop()
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
    self.text_generator:reset()
    pcall(util.unset_keymaps, settings.keymaps.start_game, globals.bufnr)

    logger:log("countdown game mode stopped")
end

function Custom:_reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        globals.bufnr,
        globals.ns_id,
        constants.info_line,
        constants.text_first_line + constants.text_num_lines + 1
    )
    self.closing = false
    self.extm_ids = {}
    self.text = { "Paste your text here." }
    self.time_sec = 0
    self.pace_cursor = nil
    self.stats:reset()
    self.ignore_next_change = true
end

function Custom:_set_extmarks()
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

function Custom:_update_extmarks()
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
---@param args on_bytes_args
function Custom:_handle_typing(args)
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
        and not self._moved_back(row, col, prev_row, prev_col)
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
    if self._moved_back(row, col, prev_row, prev_col) then
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

        self:_update_extmarks()
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
            self.word_count = self.number_of_words
            self:_update_live_progress()
            self:_update_extmarks()
            self:stop()
            self.stats.time = self.time_sec
            self.stats:display_stats()

            logger:log("reached the end of the text")

            return
        end

        if row == constants.text_middle_line then
            self.ignore_next_change = true
            self:_move_up()
            util.set_cursor_pos(cursor_row, 0, globals.winnr)

            logger:log("moved to the beginning of the middle line")
        else
            util.set_cursor_pos(cursor_row + 1, 0, globals.winnr)

            logger:log("moved to the beginning of the next line")
        end
        self:_update_extmarks()
        return
    end

    -- no more edge cases, just update the extmarks
    self:_update_extmarks()
end

---checks if the cursor has moved backwards (e.g. with `<bspace>` or `<c-u>`)
---@param row integer
---@param col integer
---@param prev_row integer
---@param prev_col integer
---@return boolean
function Custom._moved_back(row, col, prev_row, prev_col)
    return row < prev_row or (row == prev_row and col < prev_col)
end

function Custom:_move_up()
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
        -- we don't want space at the end of the last line
        self.text[#self.text] = util.trim(self.text[#self.text])
    end

    self:_set_extmarks()

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

---------------------------- timer stuff ------------------------------------------

function Custom:_update_live_progress()
    if not settings:get_selected("live_progress") then
        return
    end

    local word_count_text = settings:get_selected("demojify") and "Word count: " or "󱀽 "
    local timer_text = settings:get_selected("demojify") and "Time left: " or "󱑆 "
    self.info_extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants.info_line, 0, {
            virt_text = {
                {
                    util.center_text(
                        ("%s%s / %s        %s%s"):format(
                            word_count_text,
                            self.word_count,
                            self.number_of_words,
                            timer_text,
                            tostring(("%4.2f"):format(self.time_sec))
                        ),
                        api.nvim_win_get_width(globals.winnr)
                    ),
                    "SpeedTyperCountNormal",
                },
            },
            id = self.info_extm_id,
            priority = 50,
        })
end

function Custom:_create_timer()
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
        self:_attach_to_speedtyper_buffer()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
        vim.cmd.startinsert()
        util.set_cursor_pos(constants.text_first_line + 1, 0, globals.winnr)
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, extm_id)
        vim.schedule(function()
            util.clear_buffer_text(constants.win_height, globals.bufnr)
            self:_set_extmarks()
        end)
        self:_start_timer()
        self.pace_cursor:run()
    end, { buffer = globals.bufnr, desc = "SpeedTyper: Start the game." })
end

function Custom:_start_timer()
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.1
            self:_update_live_progress()
        end)
    )
end

return Custom.new()
