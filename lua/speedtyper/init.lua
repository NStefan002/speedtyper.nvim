local M = {}

function M.setup()
    require("speedtyper.util").notify(
        "No need to call `setup` function.",
        vim.log.levels.INFO,
        require("speedtyper.settings"):get_selected("notify_method")
    )
end

return M
