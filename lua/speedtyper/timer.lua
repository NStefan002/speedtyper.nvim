local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local helper = require("speedtyper.helper")
local stats = require("speedtyper.stats")
local runner = require("speedtyper.runner")

---@param time_sec number
---@param bufnr integer
function M.create_timer(time_sec, bufnr)
    local extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 4, 0, {
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
            M.start_countdown(bufnr, time_sec)
        end,
        desc = "Start the timer.",
    })
end

---@param bufnr integer
---@param time_sec number
function M.start_countdown(bufnr, time_sec)
    local extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 4, 0, {
        virt_text = {
            { "Time: " .. tostring(time_sec) .. "    ", "Error" },
        },
        virt_text_pos = "right_align",
    })
    local t = time_sec
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
            if t <= 0 then
                extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 4, 0, {
                    virt_text = {
                        { "Time's up!", "WarningMsg" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
                api.nvim_del_augroup_by_name("SpeedtyperTyping")
                stats.display_stats(bufnr, runner.num_of_typos, time_sec)
                timer:stop()
                timer:close()
            else
                extm_id = api.nvim_buf_set_extmark(bufnr, ns_id, 4, 0, {
                    virt_text = {
                        { "Time: " .. tostring(t) .. "    ", "Error" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
                t = t - 1
            end
        end)
    )
end

return M
