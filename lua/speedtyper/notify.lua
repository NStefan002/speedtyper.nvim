local api = vim.api

local M = {}

---notify user of an error
---@param msg string
---@param level vim.log.levels
function M.notify(msg, level)
    require("speedtyper.logger"):log(msg)

    local settings = require("speedtyper.settings")

    ---@type speedtyper.notify_method
    local method = settings:get_selected("notify_method")
    if method == "none" then
        return
    end

    require("speedtyper.sounds"):play_notification_sound()

    if method == "notify" then
        -- "\n" for nvim configs that don't use nvim-notify
        vim.notify("\n" .. msg, level, { title = "Speedtyper" })
        return
    end

    -- method == "echo"

    ---@type table<vim.log.levels, string>
    local hl_groups = {
        [vim.log.levels.TRACE] = "DiagnosticVirtualTextOk",
        [vim.log.levels.DEBUG] = "DiagnosticVirtualTextHint",
        [vim.log.levels.INFO] = "DiagnosticVirtualTextInfo",
        [vim.log.levels.WARN] = "DiagnosticVirtualTextWarn",
        [vim.log.levels.ERROR] = "DiagnosticVirtualTextError",
    }
    api.nvim_echo({
        { " speedtyper.nvim ", hl_groups[level] },
        { msg, "" },
    }, true, { verbose = false })
end

return M
