local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local words = require("speedtyper.langs").get_words()

---calculate the dimension of the floating window
---@param size number
---@param viewport integer
function M.calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@return integer
---@return integer
function M.get_cursor_pos()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return line, col
end

---@return string
function M.generate_sentence()
    local win_width = api.nvim_win_get_width(0)
    local sentence = ""
    local word = words[math.random(1, #words)]
    while #sentence + #word < 0.85 * win_width do
        sentence = word .. " " .. sentence
        word = words[math.random(1, #words)]
    end
    return sentence
end

---@param bufnr integer
---@return integer[]
---@return string[]
function M.generate_extmarks(bufnr)
    M.clear_text(bufnr)
    local extm_ids = {}
    local sentences = {}
    for i = 1, 4 do
        local sentence = M.generate_sentence()
        local extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
            virt_text = {
                { sentence, "Comment" },
            },
            hl_mode = "combine",
            virt_text_win_col = 0,
        })
        table.insert(sentences, sentence)
        table.insert(extm_ids, extm_id)
    end

    return extm_ids, sentences
end

---update extmarks according to the cursor position
---@param sentences string[]
---@param extm_ids integer[]
---@param bufnr integer
---@return integer[]
---@return string[]
function M.update_extmarks(sentences, extm_ids, bufnr)
    -- TODO: configure backspace behaviour
    local line, col = M.get_cursor_pos()

    -- move cursor to the beginning of the next line after the final space in the previous line
    if col - 1 == #sentences[line] then
        vim.cmd.normal("j0")
    end

    if line == 4 and col - 2 == #sentences[line] then
        vim.cmd.normal("gg0")
        M.clear_extmarks(extm_ids, bufnr)
        extm_ids, sentences = M.generate_extmarks(bufnr)
    else
        api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
            id = extm_ids[line],
            virt_text = {
                { string.sub(sentences[line], col), "Comment" },
            },
            virt_text_win_col = col - 1,
        })
    end

    return extm_ids, sentences
end

---@param extm_ids integer[]
---@param bufnr integer
function M.clear_extmarks(extm_ids, bufnr)
    for _, id in ipairs(extm_ids) do
        api.nvim_buf_del_extmark(bufnr, ns_id, id)
    end
end

---@param bufnr integer
function M.clear_text(bufnr)
    api.nvim_buf_set_lines(bufnr, 0, 5, false, { "", "", "", "", "" })
end

return M
