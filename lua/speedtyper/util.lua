local M = {}

function M.error(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "Speedtyper" })
end

return M
