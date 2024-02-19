local Util = require("speedtyper.util")
local TyposTracker = require("speedtyper.typo")
local Text = require("speedtyper.text")
local Position = require("speedtyper.position")

---@class SpeedTyperStopwatch
---@field timer uv_timer_t
---@field bufnr integer
---@field ns_id integer
---@field extm_ids integer[]
---@field text string[]
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field time_sec number
---@field number_of_words integer
---@field text_type string
---@field keypresses integer
---@field _prev_cursor_pos Position

local Stopwatch = {}
Stopwatch.__index = Stopwatch

---@param bufnr integer
---@param number_of_words integer
---@param text_type? string
function Stopwatch.new(bufnr, number_of_words, text_type)
    local self = {
        timer = nil,
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        keypresses = 0,
        time_sec = 0.0,
        number_of_words = number_of_words,
        text_type = text_type,
        extm_ids = {},
        text = {},
        text_generator = Text.new(),
        typos_tracker = TyposTracker.new(bufnr),
        _prev_cursor_pos = Position.new(3, 1),
    }
    -- TODO: move the next line to menu
    self.text_generator:set_lang("en")
    return setmetatable(self, Stopwatch)
end

function Stopwatch:start()
    Stopwatch._reset_values(self)
    Stopwatch._set_extmarks(self)
    Stopwatch._create_timer(self)
    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = vim.api.nvim_create_augroup("SpeedTyperStopwatch", {}),
        buffer = self.bufnr,
        callback = function()
            self.keypresses = self.keypresses + 1
            Stopwatch._update_extmarks(self)
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
    Stopwatch._reset_values(self)
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperStopwatch")
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperStopwatchTimer")
end

function Stopwatch:_reset_values()
    pcall(vim.api.nvim_buf_clear_namespace, self.bufnr, self.ns_id, 2, -1)
    self.keypresses = 0
    self.time_sec = 0.0
    self.extm_ids = {}
    self.text = {}
    self.timer = nil
    self.typos_tracker.typos = {}
    self._prev_cursor_pos:update(3, 1)
end

function Stopwatch:_set_extmarks()
    local win_width = vim.api.nvim_win_get_width(0)
    self.text = self.text_generator:generate_n_words_text(win_width, self.number_of_words)
    local n = math.min(3, #self.text)
    for i = 1, n do
        local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i + 1, 0, {
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
        table.insert(self.extm_ids, extm_id)
    end
end

function Stopwatch:_update_extmarks()
    local line, col = Util.get_cursor_pos()
    -- NOTE: don't check the current character when going backwards (e.g. with backspace)
    if
        line > self._prev_cursor_pos.line
        or (line == self._prev_cursor_pos.line and col > self._prev_cursor_pos.col)
    then
        self.typos_tracker:check_curr_char(string.sub(self.text[line - 2], col - 1, col - 1))
    end
    if line - 2 == #self.text and col - 1 == #self.text[#self.text] then
        -- no more text to type
        Stopwatch.stop(self)
        return
    end
    if col - 1 == #self.text[line - 2] or col - 2 == #self.text[line - 2] then
        if line < self._prev_cursor_pos.line or col == self._prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line, 0, {
                id = self.extm_ids[line - 1],
                virt_text = { { self.text[line - 1], "SpeedTyperTextUntyped" } },
                virt_text_win_col = 0,
            })
        else
            if line == 4 then
                Stopwatch._move_up(self)
                col = 1
            else
                vim.cmd.normal("j0")
            end
        end
    end
    vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line - 1, 0, {
        id = self.extm_ids[line - 2],
        virt_text = { { string.sub(self.text[line - 2], col), "SpeedTyperTextUntyped" } },
        virt_text_win_col = col - 1,
    })

    self._prev_cursor_pos:update(line, col)
end

function Stopwatch:_move_up()
    Util.remove_element(self.text, self.text[1])

    local n = math.min(3, #self.text)
    for i = 1, n do
        vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i + 1, 0, {
            id = self.extm_ids[i],
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
    end
    pcall(vim.api.nvim_buf_clear_namespace, self.bufnr, self.ns_id, n, 5)

    local written_lines = vim.api.nvim_buf_get_lines(self.bufnr, 2, 4, false)
    Util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    vim.api.nvim_buf_set_lines(self.bufnr, 2, 4, false, written_lines)

    -- remove typos from the first line (because the line is removed)
    -- and move typos from the second line to the first line
    local to_remove = {}
    for i, typo in ipairs(self.typos_tracker.typos) do
        if typo.line == 3 then
            table.insert(to_remove, typo)
        elseif self.typos_tracker.typos[i].line == 4 then
            self.typos_tracker.typos[i].line = 3
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
    local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, 7, 0, {
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
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<Esc>:3<CR>0i", true, false, true),
                "!",
                true
            )
            vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, extm_id)
            Stopwatch._start_timer(self)
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
