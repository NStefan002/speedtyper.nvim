local util = require("speedtyper.util")

-- internal methods
local Speedtyper = {}

-- state
local S = {
    -- Boolean determining if the plugin is enabled or not.
    enabled = false,
}

---Toggle the plugin by calling the `enable`/`disable` methods respectively.
---@private
function Speedtyper.toggle()
    if S.enabled then
        return Speedtyper.disable()
    end

    return Speedtyper.enable()
end

---Initializes the plugin.
---@private
function Speedtyper.enable()
    if S.enabled then
        return S
    end

    S.enabled = true

    return S
end

---Disables the plugin and reset the internal state.
---@private
function Speedtyper.disable()
    if not S.enabled then
        return S
    end

    -- reset the state
    S = {
        enabled = false,
    }

    return S
end

return Speedtyper
