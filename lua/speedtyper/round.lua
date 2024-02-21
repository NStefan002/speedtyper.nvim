--- TODO: finish this when other game modes are implemented
local Countdown = require("speedtyper.game_modes.countdown")
local Stopwatch = require("speedtyper.game_modes.stopwatch")
local Rain = require("speedtyper.game_modes.rain")
local Util = require("speedtyper.util")

---@class SpeedTyperRound
---@field active_game_mode SpeedTyperCountdown | SpeedTyperStopwatch | SpeedTyperRain
---@field bufnr integer
local SpeedTyperRound = {}
SpeedTyperRound.__index = SpeedTyperRound

---@param bufnr integer
function SpeedTyperRound.new(bufnr)
    local self = {
        active_game_mode = nil,
        bufnr = bufnr,
    }
    return setmetatable(self, SpeedTyperRound)
end

function SpeedTyperRound:set_game_mode(...)
    -- TODO: parse args according to game mode (implement after implementing Stopwatch and Rain)
    local args = { ... }
    local game_mode = args[1]
    if game_mode == "time" then
        -- TODO: remove hard-coded values
        self.active_game_mode = Countdown.new(self.bufnr, 30)
    elseif game_mode == "words" then
        self.active_game_mode = Stopwatch.new(self.bufnr, 15)
    elseif game_mode == "rain" then
        self.active_game_mode = Rain.new(self.bufnr)
    else
        Util.error("Invalid game mode: " .. game_mode)
    end
end

function SpeedTyperRound:start_round()
    if self.active_game_mode then
        self.active_game_mode:start()
    end
end

function SpeedTyperRound:end_round()
    if self.active_game_mode then
        self.active_game_mode:stop()
    end
end

return SpeedTyperRound
