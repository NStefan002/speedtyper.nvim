local M = {}

---@type table<string, any>
M.default_opts = {
    window = {
        height = 5, -- integer >= 5 | float in range (0, 1)
        width = 0.55, -- integer | float in range (0, 1)
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    },
    language = "en", -- "en" | "sr" currently only only supports English and Serbian
    game_modes = { -- prefered settings for different game modes
        -- type until time expires
        countdown = {
            time = 30,
        },
        -- type until you complete one page
        stopwatch = {
            hide_time = true, -- hide time while typing
        },
        -- NOTE: the window height will become the same as the window width
        rain = {
            initial_speed = 1.5, -- words fall down by one line every x seconds
            throttle = 7, -- increase speed every x seconds (set to -1 for constant speed)
            lives = 3,
        },
    },
    -- specify highlight group for each component
    highlights = {
        untyped_text = "Comment",
        typo = "ErrorMsg",
        clock = "ErrorMsg",
        falling_word_typed = "DiagnostcOk",
        falling_word = "Normal",
        falling_word_warning1 = "WarningMsg",
        falling_word_warning2 = "ErrorMsg",
    },
}

---@type table<string, any>
M.opts = {}

---@param opts table<string, any>
function M.override_opts(opts)
    M.opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})
    require("speedtyper.langs").set_lang(M.opts.language)
end

return M
