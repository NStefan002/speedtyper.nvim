local M = {}
local api = vim.api
local helper = require("speedtyper.helper")

---@param bufnr integer
---@param ns_id integer
function M.start(bufnr, ns_id)
    local extm_ids, sentences = helper.generate_extmark(bufnr, ns_id)
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("Speedtyper", { clear = true }),
        buffer = bufnr,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids, bufnr, ns_id)
        end,
        desc = "Update extmarks while typing.",
    })
end

---@param time_sec number
---@param bufnr integer
---@param ns_id integer
function M.create_timer(time_sec, bufnr, ns_id)
    local extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
        virt_text = {
            { "Time: " .. tostring(time_sec) .. "    ", "Error" },
        },
        virt_text_pos = "right_align",
    })
    local timer
    if vim.uv ~= nil then
        timer = vim.uv.new_timer()
    else
        timer = vim.loop.new_timer()
    end

    timer:start(
        0,
        1000,
        vim.schedule_wrap(function()
            if time_sec <= 0 then
                extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
                    virt_text = {
                        { "Time's up!", "WarningMsg" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
                timer:stop()
                timer:close()
            else
                extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
                    virt_text = {
                        { "Time: " .. tostring(time_sec) .. "    ", "Error" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
                time_sec = time_sec - 1
            end
        end)
    )
end

return M
