local M = {}
local api = vim.api
local util = require("speedtyper.util")
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local opts = require("speedtyper.config").opts
local hl = require("speedtyper.config").opts.highlights
local normal = vim.cmd.normal

local sentences = {}
local words = {}
if opts.sentence_mode then
    sentences = require("speedtyper.langs").get_sentences()
else
    words = require("speedtyper.langs").get_words()
end

---@type integer
M.next_word_id = 0
---@type integer
M.num_of_chars = 0
---@type string[]
M.sentence = nil

-- used to make number of lines = window height
local n_lines = opts.window.height

---@return string[]
function M.new_sentence()
    return vim.split(sentences[math.random(1, #sentences)], " ")
end

---@return string
function M.new_word()
    if opts.sentence_mode then
        M.next_word_id = M.next_word_id + 1
        if M.sentence == nil or M.next_word_id == #M.sentence then
            M.sentence = M.new_sentence()
            M.next_word_id = 0
        end
        return M.sentence[M.next_word_id + 1]
    end
    if M.next_word_id == #words then
        M.next_word_id = 0
    end
    if opts.custom_text_file and not opts.randomize then
        M.next_word_id = M.next_word_id + 1
        return words[M.next_word_id]
    end
    return words[math.random(1, #words)]
end

---@return string
function M.generate_line()
    local win_width = api.nvim_win_get_width(0)
    local border_width = 4
    local line = M.new_word()
    local word = M.new_word()
    while #line + #word < win_width - border_width do
        line = line .. " " .. word
        word = M.new_word()
    end
    return line .. " "
end

---@return integer[]
---@return string[]
function M.generate_extmarks()
    util.clear_text(n_lines)
    local extm_ids = {}
    local sentences = {}
    for i = 1, n_lines - 1 do
        local sentence = M.generate_line()
        local extm_id = api.nvim_buf_set_extmark(0, ns_id, i - 1, 0, {
            virt_text = {
                { sentence, hl.untyped_text },
            },
            hl_mode = "combine",
            virt_text_win_col = 0,
        })
        table.insert(sentences, sentence)
        table.insert(extm_ids, extm_id)
    end

    return extm_ids, sentences
end

---additional variables used for fixing edge cases
---@type integer
M.prev_line = 0
---@type integer
M.prev_col = 0

---update extmarks according to the cursor position
---@param sentences string[]
---@param extm_ids integer[]
---@return integer[]
---@return string[]
function M.update_extmarks(sentences, extm_ids)
    local line, col = util.get_cursor_pos()
    -- NOTE: so I don't forget what is going on here
    --[[
        - a lot of +- 1 because of inconsistent indexing in provided functions
        - the main problem is jumping to the end of the previous line when deleting
        - "CursorMovedI" is triggered for the 'next' (the one that has yet to be typed) character,
        so we need to examine 'previous' cursor positon
        - col - 1 and col - 2 is the product of the above statement and the fact that every line
        ends with " " (see speedtyper.util.generate_sentence), there is no logical explanation,
        the problem was aligning 0-based and 1-based indexing
      ]]
    if col - 1 == #sentences[line] or col - 2 == #sentences[line] then
        if line < M.prev_line or col == M.prev_col then
            --[[ <bspace> will remove the current line and move the cursor to the beginning of the previous,
            so we need to restore the deleted line with 'o' (could be done with api functions) and re-add the virtual text ]]
            normal("o")
            normal("k$")
            api.nvim_buf_set_extmark(0, ns_id, line, 0, {
                id = extm_ids[line + 1],
                virt_text = {
                    { sentences[line + 1], hl.untyped_text },
                },
                virt_text_win_col = 0,
            })
        elseif line == n_lines - 1 then
            -- move cursor to the beginning of the first line and generate new sentences after the final space in the last line
            normal("gg0")
            util.clear_extmarks(extm_ids)
            for _, s in pairs(sentences) do
                M.num_of_chars = M.num_of_chars + #s
            end
            return M.generate_extmarks()
        else
            -- move cursor to the beginning of the next line after the final space in the previous line
            normal("j0")
        end
    end
    api.nvim_buf_set_extmark(0, ns_id, line - 1, 0, {
        id = extm_ids[line],
        virt_text = {
            { string.sub(sentences[line], col), hl.untyped_text },
        },
        virt_text_win_col = col - 1,
    })

    M.prev_line = line
    M.prev_col = col

    return extm_ids, sentences
end

return M
