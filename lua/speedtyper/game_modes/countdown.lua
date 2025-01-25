local api = vim.api
local util = require("speedtyper.util")
local pace_cursor = require("speedtyper.pace_cursor")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class speedtyper.game_mode.countdown : speedtyper.game_mode
local Countdown = require("speedtyper.game_modes._game_mode"):new()
Countdown.__index = Countdown

---@private
function Countdown:after_start()
    self:set_keymaps()

    logger:log("time game mode started")
end

---@private
function Countdown:reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        vim.g.speedtyper_bufnr,
        vim.g.speedtyper_ns_id,
        constants.info_line,
        constants.text_first_line + constants.text_num_lines + 1
    )
    for len, active in pairs(settings.round.length) do
        if active then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.time_sec = tonumber(len)
        end
    end
    self.extm_ids = {}
    self.text_generator:reset()
    self.text_generator:update_lang()
    local win_width = api.nvim_win_get_width(vim.g.speedtyper_winnr)
    self.text = self.text_generator:generate_n_lines_text(constants.text_num_lines, win_width)
    self.word_count = 0
    self.number_of_words = -1
    -- map lines to the length of each line
    self.pace_cursor = pace_cursor.new(vim.iter(self.text)
        :map(function(line)
            return #line
        end)
        :totable())
    self.stats:reset()
    self.timer = nil
    self.ignore_next_change = true
end

---@private
---@return string
function Countdown:live_progress_text()
    if not settings:get_selected("live_progress") then
        return ""
    end

    local word_count_text = settings:get_selected("demojify") and "Word count: " or "󱀽 "
    local timer_text = settings:get_selected("demojify") and "Time left: " or "󱑆 "
    local remaining_time_text = self.time_sec <= 0 and "Time's up!"
        or ("%4.2fs"):format(self.time_sec)

    return util.center_text(
        ("%s%4d        %s%s"):format(
            word_count_text,
            self.word_count,
            timer_text,
            remaining_time_text
        ),
        api.nvim_win_get_width(vim.g.speedtyper_winnr)
    )
end

---@private
function Countdown:start_timer()
    if not self.timer then
        self.timer = vim.uv.new_timer()
    end
    self.stats.time = self.time_sec
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if self.time_sec <= 0 or not util.speedtyper_is_active() then
                self:stop()
                self.stats:display_stats()
                return
            end
            self.time_sec = self.time_sec - 0.1
            self:update_info_line(self:live_progress_text())
        end)
    )
end

return Countdown:new()
