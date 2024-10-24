local M = {}
local api = vim.api
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")
local grp = nil

local function create_autocmds()
    grp = api.nvim_create_augroup("SpeedTyperHighlight", {})
    api.nvim_create_autocmd("Colorscheme", {
        group = grp,
        pattern = "*",
        callback = function()
            vim.schedule(M.setup)
            logger:log("Colorscheme")
        end,
    })
end

function M.setup()
    if not grp then
        create_autocmds()
    end

    local active_theme = settings:get_selected("theme")
    require(("speedtyper.themes.%s"):format(active_theme)).setup()

    logger:log("theme:", active_theme)
end

return M
