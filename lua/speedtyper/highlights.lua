---@class SpeedTyperHighlights
local Highlights = {}
Highlights.__index = Highlights

function Highlights.setup()
    vim.api.nvim_set_hl(0, "SpeedTyperButtonActive", { link = "DiagnosticHint" })
    vim.api.nvim_set_hl(0, "SpeedTyperButtonInactive", { link = "Comment" })
    vim.api.nvim_set_hl(0, "SpeedTyperTextTyped", { link = "Normal" })
    vim.api.nvim_set_hl(0, "SpeedTyperTextOk", { link = "DiagnosticOk" })
    vim.api.nvim_set_hl(0, "SpeedTyperTextUntyped", { link = "Comment" })
    vim.api.nvim_set_hl(0, "SpeedTyperTextError", { link = "ErrorMsg" })
    vim.api.nvim_set_hl(0, "SpeedTyperTextWarning", { link = "WarningMsg" })
    vim.api.nvim_set_hl(0, "SpeedTyperClockNormal", { link = "Normal" })
    vim.api.nvim_set_hl(0, "SpeedTyperClockWarning", { link = "WarningMsg" })
end

return Highlights
