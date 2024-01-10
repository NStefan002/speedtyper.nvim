---@class SpeedTyperHighlights

local Highlights = {}

---@param hlconfig SpeedTyperHighlightsConfig
function Highlights.setup(hlconfig)
    vim.api.nvim_set_hl(0, "SpeedTyperButtonActive", { link = hlconfig.button_active })
    vim.api.nvim_set_hl(0, "SpeedTyperButtonInactive", { link = hlconfig.button_inactive })
    vim.api.nvim_set_hl(0, "SpeedTyperTextTyped", { link = hlconfig.text_typed })
    vim.api.nvim_set_hl(0, "SpeedTyperTextOk", { link = hlconfig.text_ok })
    vim.api.nvim_set_hl(0, "SpeedTyperTextUntyped", { link = hlconfig.text_untyped })
    vim.api.nvim_set_hl(0, "SpeedTyperTextError", { link = hlconfig.text_error })
    vim.api.nvim_set_hl(0, "SpeedTyperTextWarning", { link = hlconfig.text_warning })
    vim.api.nvim_set_hl(0, "SpeedTyperClockNormal", { link = hlconfig.clock_normal })
    vim.api.nvim_set_hl(0, "SpeedTyperClockWarning", { link = hlconfig.clock_warning })
end

return Highlights
