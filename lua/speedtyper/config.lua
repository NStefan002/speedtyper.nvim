---@class SpeedTyperConfig
---@field language string
-- TODO: next two need rework
---@field custom_text_file string | nil
---@field randomize boolean
---@field window SpeedTyperWindowConfig
---@field game_modes SpeedTyperGameModesConfig
---@field highlights SpeedTyperHighlightsConfig
---@field vim_opt SpeedTyperVimOptConfig

---@class SpeedTyperPartialConfig
---@field language? string
---@field custom_text_file? string | nil
---@field randomize? boolean
---@field window? SpeedTyperWindowConfig
---@field game_modes? SpeedTyperGameModesConfig
---@field highlights? SpeedTyperHighlightsConfig
---@field vim_opt? SpeedTyperVimOptConfig

---@class SpeedTyperGameModesConfig
---@field countdown SpeedTyperCountdownConfig
---@field rain SpeedTyperRainConfig
---@field stopwatch SpeedTyperStopwatchConfig

---@class SpeedTyperWindowConfig
---@field width number
---@field height number
---@field border string

---@class SpeedTyperCountdownConfig
---@field time number

---@class SpeedTyperRainConfig
---@field initial_speed? number
---@field speed_increase? number
---@field speed_increase_interval? number
---@field lives? integer

---@class SpeedTyperStopwatchConfig
---@field hide_time? boolean

---@class SpeedTyperHighlightsConfig
---@field untyped_text? string
---@field typo? string
---@field clock? string
---@field falling_word_typed? string
---@field falling_word? string
---@field falling_word_warning1? string
---@field falling_word_warning2? string

---@class SpeedTyperVimOptConfig
---@field guicursor? string

local Config = {}

-- NOTE: for now, this is the same default config as in v1.0.x, almost certainly will change in the future
---@return SpeedTyperConfig
function Config.get_default_config()
    return {
        -- NOTE: first thing to get changed in the future
        window = {
            height = 7,
            width = 0.45,
            border = "rounded",
        },
        language = "en", -- "en" | "sr" currently only only supports English and Serbian
        -- NOTE: next two need rework
        custom_text_file = nil,
        randomize = false,
        game_modes = {
            countdown = {
                time = 30,
            },
            stopwatch = {
                hide_time = true,
            },
            rain = {
                initial_speed = 1.5, -- words fall down by one line every x seconds
                -- speed increases by <speed_increase> every <speed_increase_interval> seconds
                speed_increase = 0.1,
                speed_increase_interval = 5,
                lives = 3,
            },
        },
        -- specify highlight group for each component
        highlights = {
            untyped_text = "Comment",
            typo = "ErrorMsg",
            clock = "ErrorMsg",
            falling_word_typed = "DiagnosticOk",
            falling_word = "Normal",
            falling_word_warning1 = "WarningMsg",
            falling_word_warning2 = "ErrorMsg",
        },
        -- this values will be restored to your prefered settings after the game ends
        vim_opt = {
            -- only applies to insert mode, while playing the game
            guicursor = vim.opt.guicursor:get(), -- "ver25" | "hor20" | "block"
        },
    }
end

---@param partial_config? SpeedTyperPartialConfig
---@param latest_config SpeedTyperConfig
---@return SpeedTyperConfig
function Config.merge_config(partial_config, latest_config)
    partial_config = partial_config or {}
    local config = latest_config or Config.get_default_config()
    config = vim.tbl_deep_extend("force", config, partial_config)
    return config
end

return Config
