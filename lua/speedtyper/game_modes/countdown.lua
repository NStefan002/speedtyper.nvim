-- TODO: move_up is different here than in the other 2 modes

local api = vim.api
local util = require("speedtyper.util")
local pace_cursor = require("speedtyper.pace_cursor")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class SpeedTyperCountdown : SpeedTyperGameMode
local Countdown = require("speedtyper.game_modes._game_mode"):new()
Countdown.__index = Countdown

---@private
function Countdown:after_start()
    self:create_timer()

    logger:log("time game mode started")
end

---@private
function Countdown:reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        globals.bufnr,
        globals.ns_id,
        constants.info_line,
        constants.text_first_line + constants.text_num_lines + 1
    )
    for len, active in pairs(settings.round.length) do
        if active then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.time_sec = tonumber(len)
        end
    end
    self.closing = false
    self.extm_ids = {}
    self.text_generator:reset()
    self.text_generator:update_lang()
    local win_width = api.nvim_win_get_width(globals.winnr)
    self.text = self.text_generator:generate_n_lines_text(constants.text_num_lines, win_width)
    self.word_count = 0
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
    local word_count_text = settings:get_selected("demojify") and "Word count: " or "󱀽 "
    local timer_text = settings:get_selected("demojify") and "Time left: " or "󱑆 "
    return util.center_text(
        ("%s%4d        %s%4.2f"):format(word_count_text, self.word_count, timer_text, self.time_sec),
        api.nvim_win_get_width(globals.winnr)
    )
end

---@private
function Countdown:start_timer()
    self.stats.time = self.time_sec
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if self.time_sec <= 0 or self.closing then
                self:stop()
                self.info_extm_id =
                    api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants.info_line, 0, {
                        virt_text = {
                            { "Time's up!", "SpeedTyperCountWarning" },
                        },
                        id = self.info_extm_id,
                        priority = 50,
                    })
                self.stats:display_stats()
                return
            end
            self:update_live_progress()
            self.time_sec = self.time_sec - 0.1
        end)
    )
end

return Countdown:new()
