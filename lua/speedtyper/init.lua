local Ui = require("speedtyper.ui")
local Config = require("speedtyper.config")

---@class SpeedTyper
---@field config SpeedTyperConfig
---@field ui SpeedTyperUI

local SpeedTyper = {}
SpeedTyper.__index = SpeedTyper

---@param partial_config? SpeedTyperPartialConfig
function SpeedTyper.new(partial_config)
    local config = Config.merge_config(partial_config, Config.get_default_config())
    local speedtyper = {
        config = config,
        ui = Ui.new(config.window),
    }
    return setmetatable(speedtyper, SpeedTyper)
end

---@param partial_config? SpeedTyperPartialConfig
function SpeedTyper.setup(partial_config)
    local speedtyper = SpeedTyper.new(partial_config)
    return speedtyper
end

return SpeedTyper
