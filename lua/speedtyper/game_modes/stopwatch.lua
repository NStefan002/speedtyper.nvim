local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local runner = require("speedtyper.runner")
local opts = require("speedtyper.config").opts.game_modes.stopwatch

M.timer = nil
M.time_sec = 0

function M.start()
    M.create_timer()
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
        stats.display_stats(runner.num_of_keypresses, runner.num_of_typos, M.time_sec)
        runner.stop()
    end
end

function M.create_timer()
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
            M.start_stopwatch()
        end,
        desc = "Start the timer.",
    })
end

function M.start_stopwatch()
    local extm_id
    if not opts.hide_time then
        extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
            virt_text = {
                { string.format("Time: %.1f    ", M.time_sec), "Error" },
            },
            virt_text_pos = "right_align",
        })
    end
    M.timer = (vim.uv or vim.loop).new_timer()

    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            M.time_sec = M.time_sec + 0.1
            if not opts.hide_time then
                extm_id = api.nvim_buf_set_extmark(0, ns_id, 4, 0, {
                    virt_text = {
                        { string.format("Time: %.1f    ", M.time_sec), "Error" },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
            end
        end)
    )
end

return M
