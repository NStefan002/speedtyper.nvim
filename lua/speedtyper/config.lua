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
        -- NOTE: window height and width will be swapped
        rain = {
            throttle = 7, -- increase speed every x seconds
            lives = 3,
        },
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
