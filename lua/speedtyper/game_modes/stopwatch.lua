local Util = require("speedtyper.util")
local TyposTracker = require("speedtyper.typo")
local Text = require("speedtyper.text")
local Stats = require("speedtyper.stats")
local Position = require("speedtyper.position")
local constants = require("speedtyper.constants")

---@class SpeedTyperStopwatch
---@field timer uv_timer_t
---@field bufnr integer
---@field ns_id integer
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

---@param bufnr integer
---@param number_of_words? integer
---@param text_type? string
function Stopwatch.new(bufnr, number_of_words, text_type)
    local self = {
        timer = nil,
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        extm_ids = {},
        text = {},
        time_sec = 0.0,
        number_of_words = number_of_words or 30,
        text_type = text_type,
        text_generator = Text.new(),
        typos_tracker = TyposTracker.new(bufnr),
        stats = Stats.new(bufnr),
        prev_cursor_pos = Position.new(0, 0),
    }
    return setmetatable(self, Stopwatch)
end

function Stopwatch:start()
    self:_reset_values()
    self:_set_extmarks()
    self:_create_timer()
    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = vim.api.nvim_create_augroup("SpeedTyperStopwatch", {}),
        buffer = self.bufnr,
        callback = function()
            self:_update_extmarks()
        end,
        desc = "Stopwatch game mode runner.",
    })
end

function Stopwatch:stop()
    self.bufnr = nil
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperStopwatch")
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperStopwatchTimer")
end

function Stopwatch:_reset_values()
    pcall(
        vim.api.nvim_buf_clear_namespace,
        self.bufnr,
        self.ns_id,
        constants._text_first_line,
        constants._info_line + 1
    )
    self.time_sec = 0.0
    self.extm_ids = {}
    local win_width = vim.api.nvim_win_get_width(0)
    self.text = self.text_generator:generate_n_words_text(win_width, self.number_of_words)
    self.timer = nil
    self.typos_tracker.typos = {}
    self.prev_cursor_pos:update(0, 0)
    self.stats:reset()
end

function Stopwatch:_set_extmarks()
    local n = math.min(constants._text_num_lines, #self.text)
    for i = 1, n do
        local line = constants._text_first_line + i - 1
        local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line, 0, {
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
        table.insert(self.extm_ids, extm_id)
    end
end

function Stopwatch:_update_extmarks()
    local line, col = Util.get_cursor_pos()
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
            vim.api.nvim_buf_set_extmark(
                self.bufnr,
                self.ns_id,
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
    vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line + constants._text_first_line, 0, {
        id = self.extm_ids[line + 1],
        virt_text = { { string.sub(self.text[line + 1], col + 1), "SpeedTyperTextUntyped" } },
        virt_text_win_col = col,
    })
    vim.api.nvim_buf_clear_namespace(
        self.bufnr,
        self.ns_id,
        #self.text + constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )

    self.prev_cursor_pos:update(line, col)
end

function Stopwatch:_move_up()
    Util.remove_element(self.text, self.text[1])
    vim.api.nvim_buf_clear_namespace(
        self.bufnr,
        self.ns_id,
        constants._text_first_line,
        constants._text_first_line + constants._text_num_lines + 1
    )
    self.extm_ids = {}
    self:_set_extmarks()

    local written_lines = vim.api.nvim_buf_get_lines(
        self.bufnr,
        constants._text_first_line,
        constants._text_middle_line + 1,
        false
    )
    Util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    vim.api.nvim_buf_set_lines(
        self.bufnr,
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
        Util.remove_element(self.typos_tracker.typos, typo)
    end
    self.typos_tracker:redraw()
end

---------------------------- timer stuff ------------------------------------------

function Stopwatch:_create_timer()
    self.timer = (vim.uv or vim.loop).new_timer()
    local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, constants._info_line, 0, {
        virt_text = {
            { "Press 'i' to start the game.", "SpeedTyperTextOk" },
        },
        virt_text_pos = "right_align",
    })
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = vim.api.nvim_create_augroup("SpeedTyperStopwatchTimer", {}),
        buffer = self.bufnr,
        once = true,
        callback = function()
            local command = string.format("<Esc>:%d<CR>I", constants._text_first_line + 1)
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes(command, true, false, true),
                "!",
                false
            )
            -- TODO: FIND OUT WHY THIS DOES NOT WORK
            -- vim.api.nvim_win_set_cursor(0, { constants._text_first_line + 1, 0 })
            vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, extm_id)
            self:_start_timer()
        end,
        desc = "Start the stopwatch game mode.",
    })
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
