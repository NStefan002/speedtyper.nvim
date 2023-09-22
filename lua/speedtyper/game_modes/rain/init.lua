local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local util = require("speedtyper.util")
local util_rain = require("speedtyper.game_modes.rain.util")
local opts = require("speedtyper.config").opts.game_modes.rain
local words = require("speedtyper.langs").get_words()

M.timer = nil
---@type number
M.t_sec = 0
---@type number
M.speed_up = 0
---@type integer
M.lives = opts.lives
---@type number
M.interval = 1.5 -- move by one line every <interval> seconds
---@type integer
M.word_count = 0
---@type table<string, any> words with their line and column numbers and highlight
M.words_set = {}

function M.start()
    -- clear data for next game
    M.t_sec = 0
    M.lives = opts.lives
    M.interval = 1.5
    M.timer = nil
    M.word_count = 0
    M.words_set = {}

    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperRain", { clear = true }),
        buffer = 0,
        callback = function()
            if util_rain.update_extmarks(M.words_set) then
                M.word_count = M.word_count + 1
                util_rain.update_stats(M.lives, M.word_count)
            end
        end,
        desc = "Update text and mark mistakes while typing.",
    })
    util.clear_text(api.nvim_win_get_height(0))
    util_rain.update_stats(M.lives, M.word_count)
    api.nvim_win_set_cursor(0, { api.nvim_win_get_height(0), 0 })
    M.create_timer()
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
    end
    api.nvim_del_augroup_by_name("SpeedtyperRain")
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
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
    local new_word = words[math.random(1, #words)]
    local col = math.random(1, n_cols - #new_word - 1)
    if col > #new_word then
        col = col - #new_word
    end
    table.insert(M.words_set, { word = new_word, line = 0, col = col, hl = "Normal" })
    local next_word_in = math.random(2, 5)
    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if M.lives == 0 then
                M.stop()
                api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
                util.clear_text(n_lines)
                api.nvim_buf_set_lines(0, 2, 3, false, { "Your score: " .. M.word_count })
                return
            end
            M.t_sec = M.t_sec + 0.1
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
                col = math.random(1, n_cols - #new_word - 1)
                if col > #new_word then
                    col = col - #new_word
                end
                table.insert(M.words_set, { word = new_word, line = 0, col = col })
                next_word_in = math.random(2, 5)
            end
            util.clear_text(n_lines - 1)
            util.clear_extmarks(extm_ids)
            extm_ids = {}
            for _, word_info in pairs(M.words_set) do
                if word_info.hl ~= "DiagnosticOk" then
                    if word_info.line > n_lines / 3 and word_info.line < n_lines * 2 / 3 then
                        word_info.hl = "WarningMsg"
                    elseif word_info.line > n_lines * 2 / 3 then
                        word_info.hl = "ErrorMsg"
                    end
                end
                table.insert(
                    extm_ids,
                    api.nvim_buf_set_extmark(0, ns_id, word_info.line, 0, {
                        virt_text = {
                            { word_info.word, word_info.hl },
                        },
                        hl_mode = "combine",
                        virt_text_win_col = word_info.col,
                    })
                )
                word_info.line = word_info.line + 1
            end
            if M.words_set[1].line == n_lines - 1 then
                if M.words_set[1].hl == "ErrorMsg" then
                    M.lives = M.lives - 1
                    util_rain.update_stats(M.lives, M.word_count)
                end
                table.remove(M.words_set, 1)
            end
        end)
    )
end

return M
