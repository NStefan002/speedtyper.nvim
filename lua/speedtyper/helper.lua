local M = {}
local api = vim.api

---@param size integer | float
---@param viewport integer
M.calc_size = function(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@param words table
---@return string
M.generate_sentence = function(words)
    -- put random words together into a sentence and make it about 80 chars
    local sentence = words[math.random(1, #words)]
    local len = #sentence
    while len <= 40 do
        local word = words[math.random(1, #words)]
        sentence = sentence .. " " .. word
        len = len + #word
    end
    return sentence
end

---@param sentences table
---@param extm_ids table
---@param bufnr integer
---@param ns_id integer
M.update_extmarks = function(sentences, extm_ids, bufnr, ns_id)
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")

    -- move cursor to the beginning of the next line after the final space in the previous line
    if col - 2 == #sentences[line] then
        vim.cmd.normal("j0")
    end

    if line == 4 and col - 2 == #sentences[line] then
        vim.cmd.normal("gg0")
        api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            " ",
            " ",
            " ",
            " ",
        })
        local words = require("speedtyper.words")
        for i = 1, 4 do
            sentences[i] = M.generate_sentence(words)
        end
    end

    api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
        id = extm_ids[line],
        virt_text = {
            { string.sub(sentences[line], col), "Comment" },
        },
        virt_text_win_col = col - 1,
    })
end

---@param extm_ids table
---@param bufnr integer
---@param ns_id integer
M.clear_extmarks = function(extm_ids, bufnr, ns_id)
    for _, id in ipairs(extm_ids) do
        api.nvim_buf_del_extmark(bufnr, ns_id, id)
    end
end

return M
