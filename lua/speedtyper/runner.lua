local M = {}
local api = vim.api
local helper = require("speedtyper.helper")

---@param bufnr integer
---@param ns_id integer
function M.start(bufnr, ns_id)
    local extm_ids, sentences = helper.generate_extmarks(bufnr, ns_id)
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperTyping", { clear = true }),
        buffer = bufnr,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids, bufnr, ns_id)
        end,
        desc = "Update extmarks while typing.",
    })
end

return M
