local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]

---@param bufnr integer
---@param n_mistakes integer
---@param time_sec number
function M.display_stats(bufnr, n_mistakes, time_sec)
    local n_chars = 0
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for _, line in pairs(lines) do
        n_chars = n_chars + #line
    end
    local diff = n_chars - n_mistakes
    local wpm = diff / (5 * time_sec) * 60
    local accuracy = diff / n_chars * 100
    local wpm_text = string.format("WPM: %.2f", wpm)
    local acc_text = string.format("Accuracy: %.2f%%", accuracy)
    api.nvim_buf_set_lines(bufnr, 0, 5, false, {
        "",
        wpm_text,
        "",
        acc_text,
        "",
    })
    api.nvim_buf_add_highlight(bufnr, ns_id, "Error", 1, 0, #wpm_text)
    api.nvim_buf_add_highlight(bufnr, ns_id, "WarningMsg", 3, 0, #acc_text)
end

return M
