local M = {}
local api = vim.api
local helper = require("speedtyper.helper")

---@param time_sec number
---@param bufnr integer
---@param ns_id integer
function M.create_timer(time_sec, bufnr, ns_id)
    local extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
        virt_text = {
            { "Press 'i' to start the game.", "WarningMsg" },
        },
        virt_text_pos = "right_align",
    })
    api.nvim_create_autocmd("InsertEnter", {
        group = api.nvim_create_augroup("SpeedtyperTimer", { clear = true }),
        buffer = bufnr,
        once = true,
        callback = function()
            api.nvim_buf_del_extmark(bufnr, ns_id, extm_id)
            M.start_countdown(time_sec, bufnr, ns_id)
        end,
    })
end

function M.start_countdown(time_sec, bufnr, ns_id)
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
