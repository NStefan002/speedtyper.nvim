local data_path = string.format("%s/speedtyper.json", vim.fn.stdpath("data"))

---@class SpeedTyperSettings
---@field text_variant table<"punctuation" | "numbers", boolean>
---@field game_mode table<"time" | "word" | "rain", boolean>
---@field length table<"15" | "30" | "60" | "120", boolean>
---@field language table<string, boolean> choose one of available languages
---@field theme table<string, boolean> choose one of predefined themes (or provide custom)
---@field randomize_theme boolean randomly select theme before every game
---@field cursor_style table<string, boolean> choose one of predifined cursor styles
---@field cursror_blinking boolean
---@field enable_pace_cursor boolean
---@field pace_cursor integer the pace cursor moves at <number> wpm
---@field pace_cursor_style table<string, boolean>
---@field pace_cursor_blinking boolean
---@field strict_space boolean when false jump to the next word when pressing <space>
---@field stop_on_error boolean can't continue typing until the mistake is fixed
---@field confidence_mode boolean no <bspace> allowed when enabled
---@field indicate_typos boolean if enabled highlights typos
---@field sound_volume table<"quiet" | "medium" | "loud", boolean>
---@field sound_on_keypress table<string, boolean> plays a short sound when the user presses a key
---@field sound_on_typo table<string, boolean> plays a short sound when the user makes a typo
---@field live_progress boolean displays remaining time for time mode, word count for word mode and remaining lives and word count for rain mode
---@field average_speed boolean displays average speed over the last 10 attempts
---@field average_accuracy boolean displays average accuracy over the last 10 attempts
local Settings = {}
Settings.__index = Settings

function Settings.new()
    local self = {
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
        pace_cursor = 100,
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
    return setmetatable(self, Settings)
end

return Settings
