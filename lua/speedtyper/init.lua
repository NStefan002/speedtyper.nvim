local M = require("speedtyper.main")
local Speedtyper = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function Speedtyper.toggle()
    -- when the config is not set to the global object, we set it
    if _G.Speedtyper.config == nil then
        _G.Speedtyper.config = require("speedtyper.config").options
    end

    _G.Speedtyper.state = M.toggle()
end

-- starts Speedtyper and set internal functions and state.
function Speedtyper.enable()
    if _G.Speedtyper.config == nil then
        _G.Speedtyper.config = require("speedtyper.config").options
    end

    local state = M.enable()

    if state ~= nil then
        _G.Speedtyper.state = state
    end

    return state
end

-- disables Speedtyper and reset internal functions and state.
function Speedtyper.disable()
    _G.Speedtyper.state = M.disable()
end

-- setup Speedtyper options and merge them with user provided ones.
function Speedtyper.setup(opts)
    _G.Speedtyper.config = require("speedtyper.config").setup(opts)
end

_G.Speedtyper = Speedtyper

return _G.Speedtyper
