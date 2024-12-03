local api = vim.api
local util = require("speedtyper.util")
local pace_cursor = require("speedtyper.pace_cursor")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class SpeedTyperStopwatch : SpeedTyperGameMode
local Stopwatch = require("speedtyper.game_modes._game_mode"):new()
Stopwatch.__index = Stopwatch

---@private
function Stopwatch:after_start()
    self:create_timer()

    logger:log("words game mode started")
end

---@private
function Stopwatch:reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        globals.bufnr,
        globals.ns_id,
        globals.info_line,
        globals.text_first_line + globals.text_num_lines + 1
    )
    for len, active in pairs(settings.round.length) do
        if active then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.number_of_words = tonumber(len)
        end
    end
    self.closing = false
    self.extm_ids = {}
    self.text_generator:reset()
    self.text_generator:update_lang()
    local win_width = api.nvim_win_get_width(globals.winnr)
    self.text = self.text_generator:generate_n_words_text(win_width, self.number_of_words)
    self.time_sec = 0.0
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
function Stopwatch:live_progress_text()
    local word_count_text = settings:get_selected("demojify") and "Word count: " or "󱀽 "
    local timer_text = settings:get_selected("demojify") and "Time: " or "󱑆 "
    return util.center_text(
        ("%s%4d / %4d        %s%4.2f"):format(
            word_count_text,
            self.word_count,
            self.number_of_words,
            timer_text,
            self.time_sec
        ),
        api.nvim_win_get_width(globals.winnr)
    )
end

---@private
function Stopwatch:start_timer()
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.1
            self:update_live_progress()
        end)
    )
end

return Stopwatch:new()
