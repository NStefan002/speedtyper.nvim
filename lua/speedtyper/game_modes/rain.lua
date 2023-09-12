local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local runner = require("speedtyper.runner")
local opts = require("speedtyper.config").opts.game_modes.rain
local words = require("speedtyper.langs").get_words()

M.timer = nil
---@type number
M.time_sec = 0
---@type integer
M.lives = opts.lives
---@type number
M.interval = 1.5 -- move by one line every <interval> seconds

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
    M.timer = (vim.uv or vim.loop).new_timer()
    local extm_id = api.nvim_buf_set_extmark(0, ns_id, 0, 0, {
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
            M.make_it_rain()
        end,
        desc = "Start the timer.",
    })
end

function M.make_it_rain()
    local extm_ids = {}
    local words_set = {}
    local n_words = math.random(3, 7)
    for _ = 1, n_words do
        table.insert(words_set, words[math.random(1, #words)])
    end
    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if M.lives == 0 then
                M.stop()
            end
            M.time_sec = M.time_sec + 0.1
            for i, word in ipairs(words_set) do
                table.insert(
                    extm_ids,
                    api.nvim_buf_set_extmark(0, ns_id, i - 1, 0, {
                        virt_text = {
                            { word, "WarningMsg" },
                        },
                        hl_mode = "combine",
                        virt_text_win_col = math.random(0, 7),
                    })
                )
            end
        end)
    )
end

return M
