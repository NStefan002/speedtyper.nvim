local M = {}
local api = vim.api
local globals = require("speedtyper.globals")

---@param name string
---@param val vim.api.keyset.highlight
local function hl(name, val)
    val.cterm = val.cterm or {}
    api.nvim_set_hl(globals.ns_id, name, val)
end

function M.setup()
    hl("SpeedTyperButtonActive", { link = "DiagnosticHint" })
    hl("SpeedTyperButtonInactive", { link = "Comment" })
    hl("SpeedTyperTextTyped", { link = "Normal" })
    hl("SpeedTyperTextOk", { link = "DiagnosticOk" })
    hl("SpeedTyperTextUntyped", { link = "Comment" })
    hl("SpeedTyperTextError", { link = "DiagnosticUnderlineError" })
    hl("SpeedTyperTextWarning", { link = "WarningMsg" })
    hl("SpeedTyperCountNormal", { link = "Normal" })
    hl("SpeedTyperCountWarning", { link = "WarningMsg" })
    hl("SpeedTyperInfo", { link = "DiagnosticInfo" })
end

return M
