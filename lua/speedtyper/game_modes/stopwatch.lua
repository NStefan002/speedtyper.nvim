local api = vim.api
local util = require("speedtyper.util")
local position = require("speedtyper.position")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperStopwatch
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field info_extm_id integer
---@field text string[]
---@field time_sec number
---@field number_of_words integer
---@field text_generator SpeedTyperText
---@field stats SpeedTyperStats
---@field prev_cursor_pos Position
local Stopwatch = {}
Stopwatch.__index = Stopwatch

---@return SpeedTyperStopwatch
function Stopwatch.new()
    local self = setmetatable({
        timer = nil,
        extm_ids = {},
        info_extm_id = nil,
        text = {},
        time_sec = 0.0,
        number_of_words = nil,
        text_generator = require("speedtyper.text"),
        stats = require("speedtyper.stats"),
        prev_cursor_pos = position.new(0, 0),
    }, Stopwatch)
    self:_apply_settings()
    return self
end

function Stopwatch:_apply_settings()
    for len, active in pairs(settings.round.length) do
        if active then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.number_of_words = tonumber(len)
        end
    end
end

function Stopwatch:start()
    self:_apply_settings()
    self.text_generator:update_lang()
    self:_reset_values()
    self:_set_extmarks()
    self:_create_timer()
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedTyperStopwatch", {}),
        buffer = globals.bufnr,
        callback = function()
            self:_update_extmarks()
        end,
        desc = "Stopwatch game mode runner.",
    })
end

function Stopwatch:stop()
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    pcall(util.unset_keymaps, settings.keymaps.start_game)
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperStopwatch")
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperStopwatchTimer")
end

function Stopwatch:_reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        globals.bufnr,
        globals.ns_id,
        constants._text_first_line,
        constants._info_line + 1
    )
    self.time_sec = 0.0
    self.extm_ids = {}
    local win_width = api.nvim_win_get_width(globals.winnr)
    self.text = self.text_generator:generate_n_words_text(
        win_width,
        self.number_of_words,
        settings.round.text_variant.numbers,
        settings.round.text_variant.punctuation
    )
    self.timer = nil
    self.prev_cursor_pos:update(0, 0)
    self.stats:reset()
end

function Stopwatch:_set_extmarks()
    self.extm_ids = {}
    local n = math.min(constants._text_num_lines, #self.text)
    for i = 1, n do
        local line = constants._text_first_line + i - 1
        local extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, line, 0, {
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
        table.insert(self.extm_ids, extm_id)
    end
end

---@return integer
function Stopwatch:_current_word()
    ---@type SpeedTyperCharInfo
    local chars = self.stats.text_info:get_table()

    local n = 0
    for _, c in ipairs(chars) do
        if c.should_be == " " then
            n = n + 1
        end
    end
    return n
end

function Stopwatch:_update_extmarks()
    -- TODO: rename line_idx or totally remove it
    local line, col = util.get_cursor_pos()
    local line_idx = line - constants._text_first_line + 1
    if
        line_idx > self.prev_cursor_pos.line
        or (line_idx == self.prev_cursor_pos.line and col > self.prev_cursor_pos.col)
    then
        local typed = api.nvim_buf_get_text(globals.bufnr, line, col - 1, line, col, {})[1]
        local curr_char = self.text[line_idx]:sub(col, col)
        if settings.general.strict_space and typed == " " and curr_char ~= " " then
            -- if the typed character is a space and it should not be a space, then jump to the next word (if possible)
            -- and fill the gaps with spaces and mark them as mistyped
            local next_space = string.find(self.text[line_idx], " ", col) or #self.text[line_idx]
            local spaces = string.rep(" ", next_space - col)
            local text_line = api.nvim_buf_get_lines(globals.bufnr, line, line + 1, false)[1]
            for i = col, next_space do
                self.stats:check_curr_char(" ", self.text[line_idx]:sub(i, i), line, i)
            end
            api.nvim_buf_set_lines(globals.bufnr, line, line + 1, false, { text_line .. spaces })
            util.set_cursor_pos(line + 1, next_space + 1, globals.winnr)
            self.stats:redraw_typos()
            self:_update_live_progress()
            return
        end

        self.stats:check_curr_char(typed, curr_char, line, col)
    else
        -- NOTE: pop characters if the cursor is moved to the left (by <bspace>, <C-w>, <C-u>, etc.)
        local diff = self.prev_cursor_pos.col - col
        if self.prev_cursor_pos.line > line then
            diff = 1
        end
        self.stats.text_info:pop_n(diff)
    end
    self:_update_live_progress()

    -- check if the challange is over (no more text to type)
    if line_idx == #self.text and col == #self.text[#self.text] - 1 then
        -- HACK: push one space so _update_live_progress can recongnise the end of the word, and then pop it
        self.stats.text_info:push(require("speedtyper.char_info").new(" ", " ", line, col))
        self:_update_live_progress()
        self.stats.text_info:pop()

        self:stop()
        self.stats.time = self.time_sec
        self.stats:display_stats()
        return
    end

    if col == #self.text[line_idx] or col - 1 == #self.text[line_idx] then
        if line_idx < self.prev_cursor_pos.line or col == self.prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            api.nvim_buf_set_extmark(
                globals.bufnr,
                globals.ns_id,
                line_idx + constants._text_first_line,
                0,
                {
                    id = self.extm_ids[line_idx + constants._text_first_line - 1],
                    virt_text = {
                        {
                            self.text[line_idx + constants._text_first_line - 1],
                            "SpeedTyperTextUntyped",
                        },
                    },
                    virt_text_win_col = 0,
                }
            )
        else
            if line_idx + constants._text_first_line - 1 == constants._text_middle_line then
                self:_move_up()
                col = 0
            else
                vim.cmd.normal("j0")
            end
        end
    end
    api.nvim_buf_set_extmark(
        globals.bufnr,
        globals.ns_id,
        line_idx + constants._text_first_line - 1,
        0,
        {
            id = self.extm_ids[line_idx],
            virt_text = {
                { self.text[line_idx]:sub(col + 1), "SpeedTyperTextUntyped" },
            },
            virt_text_win_col = col,
        }
    )

    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        #self.text + constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )

    self.prev_cursor_pos:update(line_idx, col)
end

function Stopwatch:_move_up()
    util.remove_element(self.text, self.text[1])
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )
    self:_set_extmarks()

    local written_lines = api.nvim_buf_get_lines(
        globals.bufnr,
        constants._text_first_line,
        constants._text_middle_line + 1,
        false
    )
    util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    api.nvim_buf_set_lines(
        globals.bufnr,
        constants._text_first_line,
        constants._text_middle_line + 1,
        false,
        written_lines
    )

    -- remove typos from the first line (because the line is removed)
    -- and move typos from the second line to the first line

    ---@type SpeedTyperCharInfo[]
    local text_info = self.stats.text_info:get_table()
    local to_remove = {}
    for _, info in ipairs(text_info) do
        if info.pos.line == constants._text_first_line then
            table.insert(to_remove, info)
        end
    end
    for _, info in ipairs(to_remove) do
        util.remove_element(text_info, info)
    end
    self.stats.text_info:clear()
    for _, info in ipairs(text_info) do
        info.pos:update(info.pos.line - 1, info.pos.col)
        self.stats.text_info:push(info)
    end
    self.stats:redraw_typos()
end

function Stopwatch:_update_live_progress()
    if not settings.general.live_progress then
        return
    end

    local word_count_text = settings.general.demojify and "Word count: " or "󱀽 "
    self.info_extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants._info_line, 0, {
            virt_text = {
                {
                    ("%s%s / %s    "):format(
                        word_count_text,
                        self:_current_word(),
                        self.number_of_words
                    ),
                    "SpeedTyperClockNormal",
                },
            },
            virt_text_pos = "right_align",
            id = self.info_extm_id,
        })
end

---------------------------- timer stuff ------------------------------------------

function Stopwatch:_create_timer()
    self.timer = (vim.uv or vim.loop).new_timer()
    local keys = type(settings.keymaps.start_game) == "table"
            ---@diagnostic disable-next-line: param-type-mismatch
            and table.concat(settings.keymaps.start_game, "/")
        or settings.keymaps.start_game
    local extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants._info_line, 0, {
            virt_text = {
                {
                    ("Press %s to start the game."):format(keys),
                    "SpeedTyperTextOk",
                },
            },
            virt_text_pos = "right_align",
        })
    util.set_keymaps(settings.keymaps.start_game, function()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
        vim.cmd.startinsert()
        util.set_cursor_pos(constants._text_first_line + 1, 0, globals.winnr)
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, extm_id)
        vim.schedule(function()
            util.clear_buffer_text(constants._win_height, globals.bufnr)
            self:_set_extmarks()
        end)
        self:_start_timer()
    end, { buffer = globals.bufnr, desc = "SpeedTyper: Start the game." })
end

function Stopwatch:_start_timer()
    self:_update_live_progress()
    self.timer:start(
        0,
        50,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.05
        end)
    )
end

return Stopwatch.new()
