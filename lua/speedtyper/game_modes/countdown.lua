local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local runner = require("speedtyper.runner")
local opts = require("speedtyper.config").opts.game_modes.countdown

M.timer = nil

function M.start()
    M.create_timer(opts.time)
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
        stats.display_stats(runner.num_of_keypresses, runner.num_of_typos, opts.time)
        runner.stop()
    end
end

---@param time_sec number
function M.create_timer(time_sec)
    M.timer = (vim.uv or vim.loop).new_timer()
    local extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
        virt_text = {
            { "Press 'i' to start the game.", "WarningMsg" },
        },
        virt_text_pos = "right_align",
    })
    api.nvim_create_autocmd("InsertEnter", {
        group = api.nvim_create_augroup("SpeedtyperTimer", { clear = true }),
        buffer = 0,
        once = true,
        callback = function()
            api.nvim_buf_del_extmark(0, ns_id, extm_id)
            M.start_countdown(time_sec)
        end,
        desc = "Start the timer.",
    })
end

---@param time_sec number
function M.start_countdown(time_sec)
    local extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
        virt_text = {
            { "Time: " .. tostring(time_sec) .. "    ", "Error" },
        },
        virt_text_pos = "right_align",
    })
    local t = time_sec

    M.timer:start(
        0,
        1000,
        vim.schedule_wrap(function()
            if t <= 0 then
                M.stop()
                extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
                    virt_text = {
                        { "Time's up!", "WarningMsg" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
            else
                extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
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
