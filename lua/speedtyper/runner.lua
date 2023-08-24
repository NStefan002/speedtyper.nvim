local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")
local typo = require("speedtyper.typo")

---@param bufnr integer
function M.start(bufnr)
    local extm_ids, sentences = helper.generate_extmarks(bufnr)
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperTyping", { clear = true }),
        buffer = bufnr,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids, bufnr)
            typo.check_curr_word(bufnr, sentences)
        end,
        desc = "Update extmarks while typing.",
    })
end

return M
