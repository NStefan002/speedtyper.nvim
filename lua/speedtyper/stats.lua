local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local opts = require("speedtyper.config").opts

---@param n_keypresses integer
---@param n_mistakes integer
---@param time_sec number
---@param text_len? integer
---@param text? string[]
function M.display_stats(n_keypresses, n_mistakes, time_sec, text_len, text)
    local n_chars = 0
    if text_len ~= nil then
        n_chars = text_len
    end
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
    vim.print(lines)
    local n_lines = #lines
    -- clear all lines
    local empty_lines = {}
    for _ = 1, n_lines do
        table.insert(empty_lines, "")
    end
    api.nvim_buf_set_lines(0, 0, n_lines, false, empty_lines)

    for _, line in pairs(lines) do
        n_chars = n_chars + #line
    end

    -- if number of mistakes is larger than the estimated number of words
    -- assuming 5 characters per word
    if n_chars / 5 < n_mistakes then
        api.nvim_buf_set_lines(0, 1, 1, false, {
            "Too many mistakes!",
        })
        api.nvim_buf_add_highlight(0, ns_id, "Error", 1, 0, -1)
        return
    end

    if n_chars == 0 then
        api.nvim_buf_set_lines(0, 1, 1, false, {
            "AFK detected...",
        })
        api.nvim_buf_add_highlight(0, ns_id, "Error", 1, 0, -1)
        return
    end

    local wpm = 0
    local accuracy = 0
    if opts.real_wpm then
        -- convert lines to a table of words
        local words_target = {}
        local words_typed = {}
        for _, line in pairs(lines) do
            table.insert(words_typed, vim.split(line, " "))
        end
        vim.print("words typed: " .. words_typed)
    else
        -- NOTE: count every five characters as one word for easier calculation
        wpm = (n_chars - n_mistakes) / 5 * (60 / time_sec)
        if wpm < 0 then
            wpm = 0
        end
        -- NOTE: accuracy is defined as the percentage of correct entries out of the total entries typed
        accuracy = (n_chars - n_mistakes) / n_keypresses * 100
        if accuracy < 0 then
            accuracy = 0
        end
    end

    local wpm_text = string.format("WPM: %.2f", wpm)
    local acc_text = string.format("Accuracy: %.2f%%", accuracy)
    local time_text = string.format("Time: %d seconds", time_sec)
    api.nvim_buf_set_lines(0, 0, 5, false, {
        wpm_text,
        "",
        acc_text,
        "",
        time_text,
    })
    api.nvim_buf_add_highlight(0, ns_id, "Error", 0, 0, #wpm_text)
    api.nvim_buf_add_highlight(0, ns_id, "DiagnosticWarn", 2, 0, #acc_text)
    api.nvim_buf_add_highlight(0, ns_id, "DiagnosticInfo", 4, 0, #time_text)
end

return M
