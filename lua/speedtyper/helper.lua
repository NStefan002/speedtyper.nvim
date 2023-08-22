local M = {}
local api = vim.api
local words = require("speedtyper.words")

---@param size integer | float
---@param viewport integer
function M.calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@return string
function M.generate_sentence()
    local win_width = api.nvim_win_get_width(0)
    local sentence = ""
    local word = words[math.random(1, #words)]
    while #sentence + #word < 0.9 * win_width do
        sentence = word .. " " .. sentence
        word = words[math.random(1, #words)]
    end
    return sentence
end

---@param bufnr integer
---@param ns_id integer
---@return table<integer>, table<string>
function M.generate_extmark(bufnr, ns_id)
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

---@param sentences table
---@param extm_ids table
---@param bufnr integer
---@param ns_id integer
---@return table<integer>, table<string>
function M.update_extmarks(sentences, extm_ids, bufnr, ns_id)
    -- TODO: configure backspace behaviour
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")

    -- move cursor to the beginning of the next line after the final space in the previous line
    if col - 2 == #sentences[line] then
        vim.cmd.normal("j0")
    end

    if line == 4 and col - 2 == #sentences[line] then
        vim.cmd.normal("gg0")
        M.clear_extmarks_and_text(extm_ids, bufnr, ns_id)
        extm_ids, sentences = M.generate_extmark(bufnr, ns_id)
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

---@param extm_ids table
---@param bufnr integer
---@param ns_id integer
function M.clear_extmarks_and_text(extm_ids, bufnr, ns_id)
    api.nvim_buf_set_lines(bufnr, 0, -1, false, {
        " ",
        " ",
        " ",
        " ",
    })
    for _, id in ipairs(extm_ids) do
        api.nvim_buf_del_extmark(bufnr, ns_id, id)
    end
end

return M
