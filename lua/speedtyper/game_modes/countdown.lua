local Config = require("speedtyper.config")
local Util = require("speedtyper.util")
local TyposTracker = require("speedtyper.typo")
local Text = require("speedtyper.text")
local Position = require("speedtyper.position")

---@class SpeedTyperCountdown: SpeedTyperGameMode
---@field bufnr integer
---@field ns_id integer
---@field time_sec number
---@field keypresses integer
---@field hl SpeedTyperHighlightsConfig
---@field extm_ids integer[]
---@field text string[]
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field _prev_cursor_pos Position

local Countdown = {}
Countdown.__index = Countdown

---@param bufnr? integer
function Countdown.new(bufnr)
    local config = Config.get_default_config()
    local countdown = {
        timer = nil,
        bufnr = bufnr or 0,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        time_sec = config.game_modes.countdown.time,
        keypresses = 0,
        hl = config.highlights,
        extm_ids = {},
        text = {},
        text_generator = Text.new(),
        typos_tracker = TyposTracker.new(config.highlights.typo, bufnr),
        _prev_cursor_pos = Position.new(1, 1),
    }
    countdown.text_generator:set_lang("en")
    return setmetatable(countdown, Countdown)
end

function Countdown:start()
    Countdown._reset_values(self)
    Countdown._set_extmarks(self)

    vim.api.nvim_create_autocmd("CursorMovedI", {
        group = vim.api.nvim_create_augroup("SpeedTyperCountdown", {}),
        buffer = self.bufnr,
        callback = function()
            self.keypresses = self.keypresses + 1
            Countdown._update_extmarks(self)
        end,
        desc = "Countdown game mode runner.",
    })
end

function Countdown:_reset_values()
    self.keypresses = 0
    self.extm_ids = {}
    self.text = {}
    self.timer = nil
    self.typos_tracker.typos = {}
    self._prev_cursor_pos:update(1, 1)
end

function Countdown:_set_extmarks()
    Util.clear_buffer_text(3)
    for i = 1, 3 do
        local win_width = vim.api.nvim_win_get_width(self.bufnr)
        local line = self.text_generator:generate_sentence(win_width)
        local extm_id = vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, {
            virt_text = { { line, self.hl.untyped_text } },
            virt_text_win_col = 0,
        })
        table.insert(self.text, line)
        table.insert(self.extm_ids, extm_id)
    end
end

function Countdown:_update_extmarks()
    -- NOTE: For now use the simmilar logic as in the version 1
    -- TODO: Possibly try to rewrite this mess
    local line, col = Util.get_cursor_pos()

    self.typos_tracker:check_curr_char(string.sub(self.text[line], col - 1, col - 1))

    if col - 1 == #self.text[line] or col - 2 == #self.text[line] then
        if line < self._prev_cursor_pos.line or col == self._prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line, 0, {
                id = self.extm_ids[line + 1],
                virt_text = { { self.text[line + 1], self.hl.untyped_text } },
                virt_text_win_col = 0,
            })
        else
            if line == 2 then
                Countdown._move_up(self)
                col = 1
            else
                vim.cmd.normal("j0")
            end
        end
    end
    vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, line - 1, 0, {
        id = self.extm_ids[line],
        virt_text = { { string.sub(self.text[line], col), self.hl.untyped_text } },
        virt_text_win_col = col - 1,
    })

    self._prev_cursor_pos:update(line, col)
end

function Countdown:_move_up()
    Util.remove_element(self.text, self.text[1])
    local win_width = vim.api.nvim_win_get_width(self.bufnr)
    table.insert(self.text, self.text_generator:generate_sentence(win_width))

    for i, line in ipairs(self.text) do
        vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, {
            id = self.extm_ids[i],
            virt_text = { { line, self.hl.untyped_text } },
            virt_text_win_col = 0,
        })
    end

    local written_lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, 2, false)
    Util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    vim.api.nvim_buf_set_lines(self.bufnr, 0, 2, false, written_lines)

    -- remove typos from the first line (because the line is removed)
    -- and move typos from the second line to the first line
    local to_remove = {}
    for i, typo in ipairs(self.typos_tracker.typos) do
        if typo.line == 1 then
            table.insert(to_remove, typo)
        elseif self.typos_tracker.typos[i].line == 2 then
            self.typos_tracker.typos[i].line = 1
        end
    end
    for _, typo in ipairs(to_remove) do
        Util.remove_element(self.typos_tracker.typos, typo)
    end
    self.typos_tracker:redraw()
end

return Countdown
