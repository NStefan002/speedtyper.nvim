--- TODO: finish this when other game modes are implemented
local Countdown = require("speedtyper.game_modes.countdown")
local Stopwatch = require("speedtyper.game_modes.stopwatch")
local Rain = require("speedtyper.game_modes.rain")
local Util = require("speedtyper.util")

---@class SpeedTyperRound
---@field active_game_mode SpeedTyperGameMode

---@class SpeedTyperGameMode
---@field timer uv_timer_t

local SpeedTyperRound = {}
SpeedTyperRound.__index = SpeedTyperRound

function SpeedTyperRound.new()
    local round = {
        active_game_mode = nil,
    }
    return setmetatable(round, SpeedTyperRound)
end

---@param game_mode string
function SpeedTyperRound:set_game_mode(game_mode)
    if game_mode == "countdown" then
        self.active_game_mode = Countdown.new()
    elseif game_mode == "stopwatch" then
        self.active_game_mode = Stopwatch.new()
    elseif game_mode == "rain" then
        self.active_game_mode = Rain.new()
    else
        Util.error("Invalid game mode: " .. game_mode)
    end
end

function SpeedTyperRound:start_round()
    self.active_game_mode:start()
end

function SpeedTyperRound:end_round()
    -- self.active_game_mode:stop()
end

return SpeedTyperRound
