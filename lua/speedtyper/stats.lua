local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local opts = require("speedtyper.config").opts

---@param n_keypresses integer
---@param n_mistakes integer
---@param time_sec number
---@param text_len? integer
---@param text? string[]
---@param words_typed? string[]
function M.display_stats(
  n_keypresses,
  n_mistakes,
  time_sec,
  text_len,
  text,
  prev_lines
)
    local n_chars = 0
    if text_len ~= nil then
        n_chars = text_len
    end
    local lines = api.nvim_buf_get_lines(0, 0, -1, false)
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
        if prev_lines ~= nil then
            lines = vim.list_extend(prev_lines, lines)
        end
        -- concatenate all lines as a single string
        local lines_str = table.concat(lines, "")
        -- substitute multiple spaces with a single space
        vim.print(lines_str)
        lines_str = lines_str:gsub("%s+", " ")
        -- remove trailing spaces
        lines_str = lines_str:gsub("%s$", "")
        vim.print(lines_str)
        -- split into words
        local words_typed = vim.split(lines_str, " ")
        vim.print(lines)
        vim.print(words_typed)
        vim.print(text)
        -- loop though each word typed and compare to the target text
        local n_correct = 0
        n_mistakes = 0  -- redefine n_mistakes to the end version
        for i, word in pairs(words_typed) do
            if text[i] and word == text[i] then
                n_correct = n_correct + 1
            else
                n_mistakes = n_mistakes + 1
            end
        end
        -- if the user didn't finish typing the last word then don't count it
        local n_words = #words_typed
        if text[n_words] and words_typed[n_words] ~= text[n_words] then
            n_words = #words_typed - 1
            n_mistakes = n_mistakes - 1
        end
        wpm = n_correct * (60 / time_sec)
        accuracy = n_correct / n_words * 100
    else
        -- estimate wpm by counting every five characters as a word
        -- this balances out the variation in word length
        wpm = (n_chars - n_mistakes) / 5 * (60 / time_sec)
        accuracy = (n_chars - n_mistakes) / n_keypresses * 100
    end
    if wpm < 0 then
        wpm = 0
    end
    if accuracy < 0 then
        accuracy = 0
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
