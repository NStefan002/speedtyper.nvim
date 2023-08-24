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

---@param bufnr integer
function M.start(bufnr)
    local extm_ids, sentences = helper.generate_extmarks(bufnr)
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperTyping", { clear = true }),
        buffer = bufnr,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids, bufnr)
            local curr_typo = typo.check_curr_word(bufnr, sentences)
            if curr_typo.typo_found then
                table.insert(typos, curr_typo.typo_pos)
            else
                remove_typo(typos, curr_typo.typo_pos)
            end
            M.num_of_typos = #typos
        end,
        desc = "Update extmarks and mark mistakes while typing.",
    })
end

return M
