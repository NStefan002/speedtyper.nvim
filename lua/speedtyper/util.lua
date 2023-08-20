local M = {}

M.error = function(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "Speedtyper" })
end

return M
