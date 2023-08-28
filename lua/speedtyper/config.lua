local M = {}

---@type table<string, any>
M.default_opts = {
    time = 30,
    window = {
        height = 5,          -- integer >= 5 | float in range (0, 1)
        width = 0.55,        -- integer | float in range (0, 1)
        border = "rounded",  -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    },
    language = "en",         -- currently only only supports English
    show_menu = false,       -- enable choosing between different game modes
    game_mode = "countdown", -- "limitless" | "code_snippets", this field will be ignored if show_menu is set
    highlights = {           -- set hl-groups for game components
        typo = "SpeedtyperTypo",
        wpm = "SpeedtyperWpm",
        accuracy = "SpeedtyperAccuracy"
    }
}

M.opts = {}

---@param opts table<string, any>
function M.override_opts(opts)
    M.opts = vim.tbl_deep_extend("force", M.default_opts, opts or {})
    require("speedtyper.langs").set_lang(opts.language)
end

return M
