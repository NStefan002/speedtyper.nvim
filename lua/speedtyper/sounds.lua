local api = vim.api
local util = require("speedtyper.util")
local settings = require("speedtyper.settings")

---@class SpeedTyperSounds
---@field tool string selected tool for playing sound
---@field tools table<string, fun(sound: string, volume: number): string[]>
---@field sounds_directory string
local Sounds = {}
Sounds.__index = Sounds

---@return SpeedTyperSounds
function Sounds.new()
    local self = setmetatable({}, Sounds)
    self.tools = {
        paplay = function(sound, volume)
            return {
                "paplay",
                ("%s"):format(sound),
                "--volume",
                ("%d"):format(volume),
            }
        end,
        mpv = function(sound, volume)
            return {
                "mpv",
                ("%s"):format(sound),
                ("--volume=%d"):format(volume),
            }
        end,
        ffplay = function(sound, volume)
            return {
                "ffplay",
                "-autoexit",
                "-nodisp",
                "-loglevel",
                "quiet",
                ("%s"):format(sound),
                "-volume",
                ("%d"):format(volume),
            }
        end,
        cvlc = function(sound, volume)
            return {
                "cvlc",
                "--play-and-exit",
                ("%s"):format(sound),
                ("--gain=%.2f"):format(volume),
            }
        end,
        mplayer = function(sound, volume)
            return {
                "mplayer",
                ("%s"):format(sound),
                "-volume",
                ("%.2f"):format(volume),
            }
        end,
    }
    self.sounds_directory = ("%s/assets/sounds/"):format(
        util.fuzzy_search(api.nvim_list_runtime_paths(), ".*speedtyper.nvim$")[1]
    )

    self:_check_for_tools()
    if self.tool == nil then
        util.error("No tools for playing sound available, run :checkhealth for more information.")
    end
    return self
end

---@param typo boolean
function Sounds:play_sound(typo)
    local sound = ""
    local on_keypress = settings:get_selected("sound_on_keypress")
    local on_typo = settings:get_selected("sound_on_typo")
    if on_keypress ~= "off" then
        sound = on_keypress
    end
    if typo and on_typo ~= "off" then
        sound = on_typo
    end
    if sound == "" then
        return
    end
    sound = ("%s%s.ogg"):format(self.sounds_directory, sound)
    local volume = self:_get_volume_for_tool(self.tool, settings:get_selected("sound_volume"))

    local cmd = self.tools[self.tool](sound, volume)
    vim.system(cmd, {})
end

--- scale the volume to the range the tool provides
---@param volume number between 0 and 100
---@param min number
---@param max number
---@return number
function Sounds._scale_volume(volume, min, max)
    return (volume / 100) * (max - min) + min
end

---@param tool string
---@param volume number
---@return number
function Sounds:_get_volume_for_tool(tool, volume)
    if tool == "paplay" then
        return self._scale_volume(settings:get_selected("sound_volume"), 0, 65536)
    elseif tool == "cvlc" then
        return self._scale_volume(settings:get_selected("sound_volume"), 0, 8)
    elseif util.tbl_contains({ "mpv", "ffplay", "mplayer" }, tool) then
        return volume
    end
    return 0
end

---finds which tools are available in $PATH
function Sounds:_check_for_tools()
    for tool, _ in pairs(self.tools) do
        if vim.fn.executable(tool) == 1 then
            self.tool = tool
            return
        end
    end
    self.tool = nil
end

return Sounds.new()
