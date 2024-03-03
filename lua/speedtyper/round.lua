--- TODO: finish this when other game modes are implemented
local Countdown = require("speedtyper.game_modes.countdown")
local Stopwatch = require("speedtyper.game_modes.stopwatch")
local Rain = require("speedtyper.game_modes.rain")
local Util = require("speedtyper.util")

---@class SpeedTyperRound
---@field active_game_mode SpeedTyperCountdown | SpeedTyperStopwatch | SpeedTyperRain
---@field bufnr integer
local Round = {}
Round.__index = Round

---@param bufnr integer
function Round.new(bufnr)
    local self = {
        active_game_mode = nil,
        bufnr = bufnr,
    }
    return setmetatable(self, Round)
end

function Round:set_game_mode()
    local game_mode = "time" -- default game mode
    for mode, active in pairs(vim.g.speedtyper_round_settings.game_mode) do
        if active then
            game_mode = mode
        end
    end
    local len = "30" -- default time/number of words
    for value, active in pairs(vim.g.speedtyper_round_settings.length) do
        if active then
            len = value
        end
    end
    -- TODO: finish this when text_type is implemented in game modes
    if game_mode == "time" then
        self.active_game_mode = Countdown.new(self.bufnr, tonumber(len))
    elseif game_mode == "words" then
        self.active_game_mode = Stopwatch.new(self.bufnr, tonumber(len))
    elseif game_mode == "rain" then
        self.active_game_mode = Rain.new(self.bufnr)
    else
        Util.error("Invalid game mode: " .. game_mode)
    end
end

function Round:start_round()
    if self.active_game_mode then
        self.active_game_mode:start()
    end
end

function Round:end_round()
    if self.active_game_mode then
        self.active_game_mode:stop()
    end
end

return Round
