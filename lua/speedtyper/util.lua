local M = {}
local api = vim.api

---notify user of an error
---@param msg string
function M.error(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.WARN, { title = "Speedtyper" })
end

---@param msg string
function M.info(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.INFO, { title = "Speedtyper" })
end

---@return integer
---@return integer
function M.get_cursor_pos()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return line, col
end

---@param a number
---@param b number
---@return boolean
function M.equal(a, b)
    return tostring(a) == tostring(b)
end

---@param extm_ids integer[]
function M.clear_extmarks(extm_ids)
    for _, id in pairs(extm_ids) do
        api.nvim_buf_del_extmark(0, api.nvim_get_namespaces()["Speedtyper"], id)
    end
    extm_ids = {}
end

---@param n integer number of lines to clear
function M.clear_text(n)
    local repl = {}
    for _ = 1, n do
        table.insert(repl, "")
    end
    api.nvim_buf_set_lines(0, 0, n, false, repl)
end

return M
