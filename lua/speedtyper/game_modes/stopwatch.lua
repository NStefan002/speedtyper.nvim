local api = vim.api
local util = require("speedtyper.util")
local position = require("speedtyper.position")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperStopwatch
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field text string[]
---@field time_sec number
---@field number_of_words integer
---@field text_type string
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field stats SpeedTyperStats
---@field prev_cursor_pos Position
local Stopwatch = {}
Stopwatch.__index = Stopwatch

-- TODO: remove '?'s and 'or's when the text_type option is implemented

---@param number_of_words? integer
---@param text_type? string
function Stopwatch.new(number_of_words, text_type)
    local self = setmetatable({
        timer = nil,
        extm_ids = {},
        text = {},
        time_sec = 0.0,
        number_of_words = number_of_words or 30,
        text_type = text_type,
        text_generator = require("speedtyper.text"),
        typos_tracker = require("speedtyper.typo"),
        stats = require("speedtyper.stats"),
        prev_cursor_pos = position.new(0, 0),
    }, Stopwatch)
    return self
end

function Stopwatch:start()
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
    local win_width = api.nvim_win_get_width(0)
    self.text = self.text_generator:generate_n_words_text(win_width, self.number_of_words)
    self.timer = nil
    self.prev_cursor_pos:update(0, 0)
    self.typos_tracker:reset()
    self.stats:reset()
end

function Stopwatch:_set_extmarks()
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

function Stopwatch:_update_extmarks()
    local line, col = util.get_cursor_pos()
    line = line - constants._text_first_line
    -- NOTE: don't check the current character when going backwards (e.g. with backspace)
    if
        line > self.prev_cursor_pos.line
        or (line == self.prev_cursor_pos.line and col > self.prev_cursor_pos.col)
    then
        local curr_char = string.sub(self.text[line + 1], col, col)
        if self.typos_tracker:check_curr_char(curr_char) then
            self.stats.typed_text:push({ curr_char, true })
        else
            self.stats.typed_text:push({ curr_char, false })
            self.stats.typos = self.stats.typos + 1
        end
    else
        -- NOTE: pop characters if the cursor is moved to the left (by <bspace>, <C-w>, <C-u>, etc.)
        local diff = self.prev_cursor_pos.col - col
        if self.prev_cursor_pos.line > line then
            diff = 1
        end
        for _ = 1, diff do
            self.stats.typed_text:pop()
        end
    end
    if line + 1 == #self.text and col == #self.text[#self.text] then
        -- no more text to type
        self:stop()
        self.stats.time = self.time_sec
        self.stats:display_stats()
        return
    end
    if col == #self.text[line + 1] or col - 1 == #self.text[line + 1] then
        if line < self.prev_cursor_pos.line or col == self.prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            api.nvim_buf_set_extmark(
                globals.bufnr,
                globals.ns_id,
                line + constants._text_first_line + 1,
                0,
                {
                    id = self.extm_ids[line + constants._text_first_line],
                    virt_text = {
                        {
                            self.text[line + constants._text_first_line],
                            "SpeedTyperTextUntyped",
                        },
                    },
                    virt_text_win_col = 0,
                }
            )
        else
            if line + constants._text_first_line == constants._text_middle_line then
                self:_move_up()
                col = 0
            else
                vim.cmd.normal("j0")
            end
        end
    end
    api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, line + constants._text_first_line, 0, {
        id = self.extm_ids[line + 1],
        virt_text = { { string.sub(self.text[line + 1], col + 1), "SpeedTyperTextUntyped" } },
        virt_text_win_col = col,
    })
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        #self.text + constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )

    self.prev_cursor_pos:update(line, col)
end

function Stopwatch:_move_up()
    util.remove_element(self.text, self.text[1])
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )
    self.extm_ids = {}
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
    local to_remove = {}
    for i, typo in ipairs(self.typos_tracker.typos) do
        if typo.line == constants._text_first_line then
            table.insert(to_remove, typo)
        else
            self.typos_tracker.typos[i].line = self.typos_tracker.typos[i].line - 1
        end
    end
    for _, typo in ipairs(to_remove) do
        util.remove_element(self.typos_tracker.typos, typo)
    end
    self.typos_tracker:redraw()
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
        vim.schedule(function()
            api.nvim_win_set_cursor(0, { constants._text_first_line + 1, 0 })
        end)
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, extm_id)
        self:_start_timer()
    end, { buffer = globals.bufnr, desc = "Start the words game mode." })
end

function Stopwatch:_start_timer()
    self.timer:start(
        0,
        50,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.05
        end)
    )
end

return Stopwatch
