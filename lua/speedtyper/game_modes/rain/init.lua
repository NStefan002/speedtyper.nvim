local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local util = require("speedtyper.util")
local opts = require("speedtyper.config").opts.game_modes.rain
local words = require("speedtyper.langs").get_words()

M.timer = nil
---@type number
M.t_sec = 0
---@type number
M.total_time_sec = 0
---@type number
M.speed_up = 0
---@type integer
M.lives = opts.lives
---@type number
M.interval = 1.5 -- move by one line every <interval> seconds
---@type integer
M.num_of_keypresses = 0
---@type integer
M.num_of_typos = 0

function M.start()
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperRain", { clear = true }),
        buffer = 0,
        callback = function()
            -- local curr_char = typo.check_curr_char(sentences)
            -- if curr_char.typo_found then
            --     table.insert(typos, curr_char.typo_pos)
            -- else
            --     typo.remove_typo(typos, curr_char.typo_pos)
            -- end
            M.num_of_typos = #typos
            M.num_of_keypresses = M.num_of_keypresses + 1
        end,
        desc = "Update text and mark mistakes while typing.",
    })
    util.clear_text(api.nvim_win_get_height(0))
    api.nvim_win_set_cursor(0, { api.nvim_win_get_height(0), 0 })
    M.create_timer()
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
    end
    stats.display_stats(M.num_of_keypresses, M.num_of_typos, M.total_time_sec_sec)
    api.nvim_del_augroup_by_name("SpeedtyperCountdown")
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    -- clear data for next game
    M.t_sec = 0
    M.total_time_sec = 0
    M.lives = opts.lives
    M.interval = 1.5
    M.timer = nil
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
            M.rain()
        end,
        desc = "Start the timer.",
    })
end

function M.rain()
    local extm_ids = {}
    local n_lines = api.nvim_win_get_height(0)
    local n_cols = api.nvim_win_get_width(0)
    ---@type table<string, any> words with their line and column numbers
    local words_set = {}
    local new_word = words[math.random(1, #words)]
    local col = math.random(1, n_cols)
    if col > 2 * #new_word then
        col = col - 2 * #new_word
    end
    table.insert(words_set, { word = words[math.random(1, #words)], line = 0, col = col })
    local next_word_in = math.random(2, 5)
    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if M.lives == 0 then
                M.stop()
            end
            M.t_sec = M.t_sec + 0.1
            M.total_time_sec = M.total_time_sec + 0.1
            M.speed_up = M.speed_up + 0.1
            if util.equal(M.speed_up, opts.throttle) then
                M.speed_up = 0
                M.interval = M.interval - 0.1
                if M.interval <= 0.1 then
                    M.interval = 0.1
                end
                M.t_sec = M.t_sec - 0.1
            end
            if not util.equal(M.t_sec, M.interval) then
                return
            end
            M.t_sec = 0
            next_word_in = next_word_in - 1
            if next_word_in == 0 then
                new_word = words[math.random(1, #words)]
                col = math.random(1, n_cols)
                if col > 2 * #new_word then
                    col = col - 2 * #new_word
                end
                table.insert(
                    words_set,
                    { word = words[math.random(1, #words)], line = 0, col = col }
                )
                next_word_in = math.random(2, 5)
            end
            util.clear_text(n_lines - 1)
            util.clear_extmarks(extm_ids)
            extm_ids = {}
            for i, word_info in ipairs(words_set) do
                table.insert(
                    extm_ids,
                    api.nvim_buf_set_extmark(0, ns_id, word_info.line, 0, {
                        virt_text = {
                            { word_info.word, "WarningMsg" },
                        },
                        hl_mode = "combine",
                        -- virt_text_win_col = math.random(1, n_cols),
                        virt_text_win_col = word_info.col,
                    })
                )
                word_info.line = word_info.line + 1
            end
            if words_set[1].line == n_lines - 1 then
                table.remove(words_set, 1)
            end
        end)
    )
end

return M
