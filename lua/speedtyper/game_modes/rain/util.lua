local M = {}
local api = vim.api

---@param words_set table<string, any>
---@return boolean
function M.update_extmarks(words_set)
    local text = api.nvim_buf_get_lines(0, -2, -1, false)[1]
    for _, word_info in pairs(words_set) do
        if text == word_info.word then
            word_info.hl = "DiagnosticOk"
            api.nvim_buf_set_lines(0, -2, -1, false, { "" })
            return true
        end
    end
    return false
end

return M
