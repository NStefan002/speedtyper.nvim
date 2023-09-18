local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local util = require("speedtyper.util")
local opts = require("speedtyper.config").opts.game_modes.rain
local words = require("speedtyper.langs").get_words()

M.timer = nil
---@type number
M.time_sec = 0
---@type integer
M.lives = opts.lives
---@type number
M.interval = 1.5 -- move by one line every <interval> seconds

---@type integer
M.num_of_keypresses = 0

---@type integer
M.num_of_typos = 0

function M.start()
    M.create_timer()
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
        stats.display_stats(M.num_of_keypresses, M.num_of_typos, M.time_sec)
        M.time_sec = 0
        M.lives = opts.lives
        M.interval = 1.5
        M.timer = nil
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
    ---@type table<string, integer> words with their line numbers
    local words_set = {}
    table.insert(words_set, { words[math.random(1, #words)], 0 })
    local next_word_in = math.random(2, 5)
    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if M.lives == 0 then
                M.stop()
            end
            M.time_sec = M.time_sec + 0.1
            if util.equal(M.time_sec, opts.throttle) then
                M.interval = M.interval - 0.1
            end
            if not util.equal(M.time_sec, M.interval) then
                return
            end
            M.time_sec = 0
            next_word_in = next_word_in - 1
            if next_word_in == 0 then
                table.insert(words_set, { words[math.random(1, #words)], 0 })
                next_word_in = math.random(2, 5)
            end
            util.clear_text(math.floor(vim.opt.lines:get() / 2))
            util.clear_extmarks(extm_ids)
            for _, word in ipairs(words_set) do
                table.insert(
                    extm_ids,
                    api.nvim_buf_set_extmark(0, ns_id, word[2], 0, {
                        virt_text = {
                            { word[1], "WarningMsg" },
                        },
                        hl_mode = "combine",
                        virt_text_win_col = math.random(1, math.floor(vim.opt.columns:get() / 4)),
                    })
                )
                word[2] = word[2] + 1
            end
        end)
    )
end

return M
