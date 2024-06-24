-- TODO: implement default settings (use it in menu to reset settings)

local settings_path = ("%s/speedtyper-settings.json"):format(vim.fn.stdpath("data"))

-- NOTE: see each field info in instructions.lua

---@class SpeedTyperRoundSettings
---@field text_variant table<"punctuation" | "numbers", boolean>
---@field game_mode table<"time" | "word" | "rain", boolean>
---@field length table<"15" | "30" | "60" | "120", boolean>

---@class SpeedTyperGeneralSettings
---@field language table<string, boolean>
---@field theme table<string, boolean>
---@field randomize_theme boolean
---@field cursor_style table<string, boolean>
---@field cursor_blinking boolean
---@field enable_pace_cursor boolean
---@field pace_cursor integer
---@field pace_cursor_style table<string, boolean>
---@field pace_cursor_blinking boolean
---@field strict_space boolean
---@field stop_on_error boolean
---@field confidence_mode boolean
---@field indicate_typos boolean
---@field sound_volume table<"quiet" | "medium" | "loud", boolean>
---@field sound_on_keypress table<string, boolean>
---@field sound_on_typo table<string, boolean>
---@field live_progress boolean
---@field average_speed boolean
---@field average_accuracy boolean
---@field debug_mode boolean

---@class SpeedTyperKeymapSettings
---@field start_game string
---@field hover string
---@field press_button string
---TODO: add more

---@class SpeedTyperSettings
---@field round SpeedTyperRoundSettings
---@field general SpeedTyperGeneralSettings
---@field keymaps SpeedTyperKeymapSettings
local Settings = {}
Settings.__index = Settings

---@return SpeedTyperSettings
function Settings.new()
    local self = setmetatable({
        round = {
            text_variant = {
                ["punctuation"] = false,
                ["numbers"] = false,
            },
            game_mode = {
                ["time"] = true,
                ["words"] = false,
                ["rain"] = false,
                ["custom"] = false,
            },
            length = {
                ["15"] = false,
                ["30"] = true,
                ["60"] = false,
                ["120"] = false,
            },
        },

        general = {
            language = {
                ["english"] = true,
                ["serbian"] = false,
            },
            theme = {
                ["default"] = true,
                ["custom"] = false,
            },
            randomize_theme = false,
            cursor_style = {
                ["line"] = true,
                ["block"] = false,
                ["underline"] = false,
            },
            cursor_blinking = false,
            enable_pace_cursor = false,
            pace_cursor = 100,
            pace_cursor_style = {
                ["line"] = true,
                ["block"] = false,
                ["underline"] = false,
            },
            pace_cursor_blinking = false,
            strict_space = false,
            stop_on_error = false,
            confidence_mode = false,
            indicate_typos = true,
            sound_volume = {
                ["quiet"] = false,
                ["medium"] = true,
                ["loud"] = false,
            },
            sound_on_keypress = {
                ["off"] = true,
                ["click"] = false,
                ["pop"] = false,
            },
            sound_on_typo = {
                ["off"] = true,
                ["click"] = false,
                ["pop"] = false,
            },
            live_progress = true,
            average_speed = false,
            average_accuracy = false,
            debug_mode = false,
        },

        keymaps = {
            start_game = "i",
            hover = "k",
            press_button = "<CR>",
        },
    }, Settings)
    return self
end

function Settings:load()
    local settings = {}
    local file, _ = io.open(settings_path, "r")
    if file then
        local json = file:read("*a")
        file:close()
        settings = vim.fn.json_decode(json)
    end
    self.round = vim.tbl_deep_extend("force", self.round, settings.round or {})
    self.general = vim.tbl_deep_extend("force", self.general, settings.general)
    self.keymaps = vim.tbl_deep_extend("force", self.keymaps, settings.keymaps or {})
end

function Settings:save()
    local settings = {
        round = self.round,
        general = self.general,
        keymaps = self.keymaps,
    }
    local json = vim.fn.json_encode(settings)
    local file = io.open(settings_path, "w")
    if file then
        file:write(json)
        file:close()
    else
        require("speedtyper.util").error("Failed to save settings")
    end
end

-- ---@param type "round" | "general"
-- function Settings:get_text_representation(type)
--     if type == "round" then
--         return " punctuation   numbers | time   words   rain   custom | 15   30   60   120 "
--     end
--
-- end

return Settings.new()
