--- TODO: finish this when other game modes are implemented
local countdown = require("speedtyper.game_modes.countdown")
local stopwatch = require("speedtyper.game_modes.stopwatch")
local rain = require("speedtyper.game_modes.rain")
local util = require("speedtyper.util")
local settings = require("speedtyper.settings")

---@class SpeedTyperRound
---@field active_game_mode SpeedTyperCountdown | SpeedTyperStopwatch | SpeedTyperRain
local Round = {}
Round.__index = Round

function Round.new()
    local self = setmetatable({
        active_game_mode = nil,
    }, Round)
    return self
end

function Round:set_game_mode()
    local game_mode = "time" -- default game mode
    for mode, active in pairs(settings.round.game_mode) do
        if active then
            game_mode = mode
        end
    end
    local len = "30" -- default time/number of words
    for value, active in pairs(settings.round.length) do
        if active then
            len = value
        end
    end
    -- TODO: finish this when text_type is implemented in game modes
    if game_mode == "time" then
        self.active_game_mode = countdown.new(tonumber(len))
    elseif game_mode == "words" then
        self.active_game_mode = stopwatch.new(tonumber(len))
    elseif game_mode == "rain" then
        self.active_game_mode = rain.new()
    else
        util.error("Invalid game mode: " .. game_mode)
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

return Round.new()
