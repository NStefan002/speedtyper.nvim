local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")

---@param bufnr integer
---@param line integer
---@param col integer index of the char that needs to be highlighted
function M.mark_word(bufnr, line, col)
    api.nvim_buf_add_highlight(bufnr, ns_id, "Error", line - 1, col - 1, col)
end

---@param bufnr integer
---@param sentences table<string>
function M.check_curr_word(bufnr, sentences)
    local line, col = helper.get_cursor_pos()
    local char_under_cursor = api.nvim_buf_get_text(bufnr, line - 1, col - 2, line - 1, col, {})[1]
    if char_under_cursor ~= string.sub(sentences[line], col - 1, col - 1) then
        M.mark_word(bufnr, line, col - 1)
    end
end

return M
