local M = {}

---notify user of an error
---@param msg string
function M.error(msg)
    vim.notify(msg, vim.log.levels.WARN, { title = "Speedtyper" })
end

---@param msg string
function M.info(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "Speedtyper" })
end

return M
