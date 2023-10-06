local M = {}
local api = vim.api
local opts = require("speedtyper.config").opts
local hl = opts.highlights
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local words = require("speedtyper.langs").get_words()

M.next_word_id = 0

---@return string
function M.new_word()
    if M.next_word_id == #words then
        M.next_word_id = 0
    end
    if opts.custom_text_file and not opts.randomize then
        M.next_word_id = M.next_word_id + 1
        return words[M.next_word_id]
    end
    return words[math.random(1, #words)]
end

---@param words_set table<string, any>
---@return boolean
function M.update_extmarks(words_set)
    local text = api.nvim_buf_get_lines(0, -2, -1, false)[1]
    for _, word_info in pairs(words_set) do
        if text == word_info.word then
            word_info.hl = hl.falling_word_typed
            api.nvim_buf_set_lines(0, -2, -1, false, { "" })
            return true
        end
    end
    return false
end

---@param lives integer
---@param word_count integer
function M.update_stats(lives, word_count)
    api.nvim_buf_clear_namespace(0, ns_id, api.nvim_win_get_height(0) - 1, -1)
    api.nvim_buf_set_extmark(0, ns_id, api.nvim_win_get_height(0) - 1, 0, {
        virt_text = {
            { " " .. tostring(word_count) .. " | ", "WarningMsg" },
            { string.rep("󰣐", lives, "") .. " ", "ErrorMsg" },
        },
        virt_text_pos = "right_align",
    })
end

return M
