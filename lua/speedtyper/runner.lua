local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")
local typo = require("speedtyper.typo")

---similar to table.remove
---@param typos table
---@param typo_pos any
local function remove_typo(typos, typo_pos)
    for i, value in ipairs(typos) do
        if value.line == typo_pos.line and value.col == typo_pos.col then
            table.remove(typos, i)
        end
    end
end

---@type integer
M.num_of_typos = 0

---@type integer
M.num_of_keypresses = 0

---@param bufnr integer
function M.start(bufnr)
    local extm_ids, sentences = helper.generate_extmarks(bufnr)
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperTyping", { clear = true }),
        buffer = bufnr,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids, bufnr)
            local curr_char = typo.check_curr_char(bufnr, sentences)
            if curr_char.typo_found then
                table.insert(typos, curr_char.typo_pos)
            else
                remove_typo(typos, curr_char.typo_pos)
            end
            M.num_of_typos = #typos
            M.num_of_keypresses = M.num_of_keypresses + 1
        end,
        desc = "Update extmarks and mark mistakes while typing.",
    })
end

---@param bufnr integer
function M.stop(bufnr)
    api.nvim_del_augroup_by_name("SpeedtyperTyping")
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    -- clear data for next game
    M.num_of_keypresses = 0
    M.num_of_typos = 0
end

return M
