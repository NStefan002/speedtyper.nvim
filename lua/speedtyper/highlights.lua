local M = {}
local api = vim.api
local globals = require("speedtyper.globals")
local grp = nil

local function create_autocmds()
    grp = api.nvim_create_augroup("SpeedTyperHighlight", {})
    api.nvim_create_autocmd("Colorscheme", {
        group = grp,
        pattern = "*",
        callback = function()
            M.setup()
        end,
    })
end

function M.setup()
    if not grp then
        create_autocmds()
    end

    api.nvim_set_hl(globals.ns_id, "SpeedTyperButtonActive", { link = "DiagnosticHint" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperButtonInactive", { link = "Comment" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperTextTyped", { link = "Normal" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperTextOk", { link = "DiagnosticOk" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperTextUntyped", { link = "Comment" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperTextError", { link = "ErrorMsg" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperTextWarning", { link = "WarningMsg" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperClockNormal", { link = "Normal" })
    api.nvim_set_hl(globals.ns_id, "SpeedTyperClockWarning", { link = "WarningMsg" })
end

return M
