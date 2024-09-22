local M = {}
local api = vim.api
local settings = require("speedtyper.settings")
local grp = nil

local function create_autocmds()
    grp = api.nvim_create_augroup("SpeedTyperHighlight", {})
    api.nvim_create_autocmd("Colorscheme", {
        group = grp,
        pattern = "*",
        callback = function()
            vim.schedule(M.setup)
        end,
    })
end

function M.setup()
    if not grp then
        create_autocmds()
    end

    local active_theme = "default"
    for theme, active in pairs(settings.general.theme) do
        if active then
            active_theme = theme
            break
        end
    end
    require("speedtyper.themes." .. active_theme).setup()
end

return M
