local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")

---@param line integer
---@param col integer index of the char that needs to be highlighted
function M.mark_typo(line, col)
    api.nvim_buf_add_highlight(0, ns_id, "Error", line - 1, col - 1, col)
end

---returns the information about the character under the cursor (is it typo or not)
---@param sentences string[]
---@return table
function M.check_curr_char(sentences)
    local line, col = helper.get_cursor_pos()
    -- when autocmd for CursorMovedI is fired the cursor is 1 char ahead of the one we need
    col = col - 1
    local char_under_cursor = api.nvim_buf_get_text(0, line - 1, col - 1, line - 1, col, {})[1]
    local typo_found = false
    if char_under_cursor ~= string.sub(sentences[line], col, col) then
        M.mark_typo(line, col)
        typo_found = true
    end
    return {
        typo_pos = { line = line, col = col },
        typo_found = typo_found,
    }
end

return M
