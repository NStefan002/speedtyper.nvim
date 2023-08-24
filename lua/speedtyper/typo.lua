local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")

---@param bufnr integer
---@param line integer
---@param col integer index of the char that needs to be highlighted
function M.mark_typo(bufnr, line, col)
    api.nvim_buf_add_highlight(bufnr, ns_id, "Error", line - 1, col - 1, col)
end

---@param bufnr integer
---@param sentences string[]
function M.check_curr_word(bufnr, sentences)
    local line, col = helper.get_cursor_pos()
    col = col - 1 -- when autocmd for CursorMovedI is fired the cursor is 1 char behind the one we need
    local char_under_cursor =
        api.nvim_buf_get_text(bufnr, line - 1, col - 1, line - 1, col + 1, {})[1]
    local typo_found = false
    if char_under_cursor ~= string.sub(sentences[line], col, col) then
        M.mark_typo(bufnr, line, col)
        typo_found = true
    end
    return {
        typo_pos = { line = line, col = col },
        typo_found = typo_found,
    }
end

return M
