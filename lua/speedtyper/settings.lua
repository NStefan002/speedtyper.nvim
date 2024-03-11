local settings_path = string.format("%s/speedtyper-settings.json", vim.fn.stdpath("data"))

---@alias Switch table<"on" | "off", boolean>

-- NOTE: see each field info in instructions.lua

---@class SpeedTyperRoundSettings
---@field text_variant table<"punctuation" | "numbers", boolean>
---@field game_mode table<"time" | "word" | "rain", boolean>
---@field length table<"15" | "30" | "60" | "120", boolean>

---@class SpeedTyperSettings
---@field language table<string, boolean>
---@field theme table<string, boolean>
---@field randomize_theme Switch
---@field cursor_style table<string, boolean>
---@field cursor_blinking Switch
---@field enable_pace_cursor Switch
-- ---@field pace_cursor integer TODO: add this later
---@field pace_cursor_style table<string, boolean>
---@field pace_cursor_blinking Switch
---@field strict_space Switch
---@field stop_on_error Switch
---@field confidence_mode Switch
---@field indicate_typos Switch
---@field sound_volume table<"quiet" | "medium" | "loud", boolean>
---@field sound_on_keypress table<string, boolean>
---@field sound_on_typo table<string, boolean>
---@field live_progress Switch
---@field average_speed Switch
---@field average_accuracy Switch

---@type SpeedTyperSettings
local default_settings = {
    language = {
        ["english"] = true,
        ["serbian"] = false,
    },
    theme = {
        ["default"] = true,
        ["custom"] = false,
    },
    randomize_theme = {
        ["on"] = false,
        ["off"] = true,
    },
    cursor_style = {
        ["line"] = true,
        ["block"] = false,
        ["underline"] = false,
    },
    cursor_blinking = {
        ["on"] = false,
        ["off"] = true,
    },
    enable_pace_cursor = {
        ["on"] = false,
        ["off"] = true,
    },
    -- pace_cursor = 100,
    pace_cursor_style = {
        ["line"] = true,
        ["block"] = false,
        ["underline"] = false,
    },
    pace_cursor_blinking = {
        ["on"] = false,
        ["off"] = true,
    },
    strict_space = {
        ["on"] = false,
        ["off"] = true,
    },
    stop_on_error = {
        ["on"] = false,
        ["off"] = true,
    },
    confidence_mode = {
        ["on"] = false,
        ["off"] = true,
    },
    indicate_typos = {
        ["on"] = true,
        ["off"] = false,
    },
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
    live_progress = {
        ["on"] = true,
        ["off"] = false,
    },
    average_speed = {
        ["on"] = false,
        ["off"] = true,
    },
    average_accuracy = {
        ["on"] = false,
        ["off"] = true,
    },
}

---@type SpeedTyperRoundSettings
local default_round_settings = {
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
}

local Settings = {}

function Settings.load()
    local settings = {}
    local file = io.open(settings_path, "r")
    if file then
        local json = file:read("*a")
        file:close()
        settings = vim.fn.json_decode(json)
    end
    settings.speedtyper_settings =
        vim.tbl_deep_extend("force", default_settings, settings.speedtyper_settings or {})
    settings.speedtyper_round_settings = vim.tbl_deep_extend(
        "force",
        default_round_settings,
        settings.speedtyper_round_settings or {}
    )
    vim.g.speedtyper_round_settings = settings.speedtyper_round_settings
    vim.g.speedtyper_settings = settings.speedtyper_settings
end

function Settings.save()
    local settings = {
        speedtyper_round_settings = vim.g.speedtyper_round_settings,
        speedtyper_settings = vim.g.speedtyper_settings,
    }
    local json = vim.fn.json_encode(settings)
    local file = io.open(settings_path, "w")
    if file then
        file:write(json)
        file:close()
    else
        error("SpeedTyper: failed to save settings")
    end
end

return Settings
