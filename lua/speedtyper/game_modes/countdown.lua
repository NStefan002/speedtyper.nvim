local Util = require("speedtyper.util")
local TyposTracker = require("speedtyper.typo")
local Text = require("speedtyper.text")
local Stats = require("speedtyper.stats")
local Position = require("speedtyper.position")

---@class SpeedTyperCountdown
---@field timer uv_timer_t
---@field bufnr integer
---@field ns_id integer
---@field extm_ids integer[]
---@field text string[]
---@field time_sec number
---@field text_type string
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field stats SpeedTyperStats
---@field prev_cursor_pos Position
local Countdown = {}
Countdown.__index = Countdown

-- TODO: remove '?'s and 'or's when the text_type option is implemented

---@param bufnr integer
---@param time? number
---@param text_type? string
function Countdown.new(bufnr, time, text_type)
    local self = {
        timer = nil,
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        extm_ids = {},
        text = {},
        time_sec = time or 30,
        text_type = text_type,
        text_generator = Text.new(),
        typos_tracker = TyposTracker.new(bufnr),
        stats = Stats.new(bufnr),
        prev_cursor_pos = Position.new(3, 1),
    }
    self.text_generator:set_lang("en")
    return setmetatable(self, Countdown)
end

function Countdown:start()
    self:_reset_values()
    self:_set_extmarks()
    self:_create_timer()

    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = vim.api.nvim_create_augroup("SpeedTyperCountdown", {}),
        buffer = self.bufnr,
        callback = function()
            self:_update_extmarks()
        end,
        desc = "Countdown game mode runner.",
    })
end

function Countdown:stop()
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    self:_reset_values()
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperCountdown")
    pcall(vim.api.nvim_del_augroup_by_name, "SpeedTyperCountdownTimer")
end

function Countdown:_reset_values()
    pcall(vim.api.nvim_buf_clear_namespace, self.bufnr, self.ns_id, 2, -1)
    self.extm_ids = {}
    self.text = {}
    self.typos_tracker.typos = {}
    self.prev_cursor_pos:update(3, 1)
    self.stats:reset()
end

function Countdown:_set_extmarks()
    local win_width = vim.api.nvim_win_get_width(0)
    for i = 1, 3 do
        local line = self.text_generator:generate_sentence(win_width)
        local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i + 1, 0, {
            virt_text = { { line, "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
        table.insert(self.text, line)
        table.insert(self.extm_ids, extm_id)
    end
end

-- TODO: change hard-coded values
function Countdown:_update_extmarks()
    -- NOTE: For now use the simmilar logic as in the version 1
    -- TODO: Possibly try to rewrite this mess
    local line, col = Util.get_cursor_pos()
    if
        line > self.prev_cursor_pos.line
        or (line == self.prev_cursor_pos.line and col > self.prev_cursor_pos.col)
    then
        local curr_char = string.sub(self.text[line - 2], col - 1, col - 1)
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

    if col - 1 == #self.text[line - 2] or col - 2 == #self.text[line - 2] then
        if line < self.prev_cursor_pos.line or col == self.prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line, 0, {
                id = self.extm_ids[line - 1],
                virt_text = { { self.text[line - 1], "SpeedTyperTextUntyped" } },
                virt_text_win_col = 0,
            })
        else
            if line == 4 then
                self:_move_up()
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

    self.prev_cursor_pos:update(line, col)
end

function Countdown:_move_up()
    Util.remove_element(self.text, self.text[1])
    local win_width = vim.api.nvim_win_get_width(0)
    table.insert(self.text, self.text_generator:generate_sentence(win_width))

    for i, line in ipairs(self.text) do
        vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i + 1, 0, {
            id = self.extm_ids[i],
            virt_text = { { line, "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
    end

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

function Countdown:_create_timer()
    self.timer = (vim.uv or vim.loop).new_timer()
    local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, 7, 0, {
        virt_text = {
            { "Press 'i' to start the game.", "SpeedTyperTextOk" },
        },
        virt_text_pos = "right_align",
    })
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = vim.api.nvim_create_augroup("SpeedTyperCountdownTimer", {}),
        buffer = self.bufnr,
        once = true,
        callback = function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<Esc>:3<CR>0i", true, false, true),
                "!",
                true
            )
            vim.api.nvim_buf_del_extmark(self.bufnr, self.ns_id, extm_id)
            self:_start_timer()
        end,
        desc = "Start the countdown game mode.",
    })
end

function Countdown:_start_timer()
    local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, 7, 0, {
        virt_text = {
            { "󱑆 " .. tostring(self.time_sec) .. "    ", "SpeedTyperClockNormal" },
        },
        virt_text_pos = "right_align",
    })
    local remaining_time = self.time_sec

    self.timer:start(
        0,
        1000,
        vim.schedule_wrap(function()
            if remaining_time <= 0 then
                self.stats.time = self.time_sec
                self.stats:display_stats()
                self:stop()
                extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, 7, 0, {
                    virt_text = {
                        { "Time's up!", "SpeedTyperClockWarning" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
            else
                extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, 7, 0, {
                    virt_text = {
                        { "󱑆 " .. tostring(remaining_time) .. "    ", "SpeedTyperClockNormal" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
                remaining_time = remaining_time - 1
            end
        end)
    )
end

return Countdown
