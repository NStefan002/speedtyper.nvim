local M = {}

---@param tools string[]
---@return table<string, boolean>
local function check_for_tools(tools)
    return vim.iter(tools)
        :map(function(tool)
            return { tool, vim.fn.executable(tool) == 1 }
        end)
        :totable()
end

function M.check()
    vim.health.start("Neovim version:")
    if vim.version().minor >= 0 then
        vim.health.ok("Met the minimum version requirement.")
    else
        vim.health.error("Upgrade to version 0.10.4 or higher.")
    end

    vim.health.start("Settings file:")
    local settings_path = ("%s/speedtyper-settings.json"):format(vim.fn.stdpath("data"))
    if vim.fn.filereadable(settings_path) == 1 then
        vim.health.ok(("Settings file found at: %s"):format(settings_path))
    else
        vim.health.warn("Settings file not found or not readable.")
    end

    vim.health.start("Sound tools:")
    local tools = check_for_tools(vim.tbl_keys(require("speedtyper.sounds").tools))
    for _, tool in ipairs(tools) do
        if tool[2] then
            vim.health.ok(("%s is available in the PATH"):format(tool[1]))
        else
            vim.health.warn(("%s is not available in the PATH"):format(tool[1]))
        end
    end
end

return M
