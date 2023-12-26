local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local util = require("speedtyper.util")
local util_rain = require("speedtyper.game_modes.rain.util")
local config = require("speedtyper.config")
local opts = config.opts.game_modes.rain
local hl = config.opts.highlights

M.timer = nil
---@type number
M.t_sec = 0
---@type number
M.speed_up = 0
---@type integer
M.lives = opts.lives
---@type number
M.interval = opts.initial_speed -- move by one line every <interval> seconds
---@type integer
M.word_count = 0
---@type table<string, any> words with their line and column numbers and highlight
M.words_set = {}

function M.start()
    -- clear data for next game
    M.t_sec = 0
    M.lives = opts.lives
    M.interval = opts.initial_speed
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

---@param ok boolean did the user force stop the game before it ended (does not have that much impact on this game mode)
function M.stop(ok)
    if ok then
        -- exit insert mode
        api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    elseif M.timer ~= nil then
        util.info("You have left the game. Exiting...")
    end
    if M.timer then
        M.timer:stop()
        M.timer:close()
        M.timer = nil
    end
    pcall(api.nvim_del_augroup_by_name, "SpeedtyperRain")
    config.restore_opts()
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
    local new_word = util_rain.new_word()
    local col = math.random(1, n_cols - #new_word - 1)
    if col > #new_word then
        col = col - #new_word
    end
    table.insert(M.words_set, { word = new_word, line = 0, col = col, hl = hl.falling_word })
    local next_word_in = math.random(2, 5)
    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if M.lives == 0 then
                M.stop(true)
                api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
                util.clear_text(n_lines)
                api.nvim_buf_set_lines(0, 2, 3, false, { "Your score: " .. M.word_count })
                util.disable_modifying_buffer()
                return
            end
            M.t_sec = M.t_sec + 0.1
            M.speed_up = M.speed_up + 0.1
            if util.equal(M.speed_up, opts.throttle) then
                M.speed_up = 0
                M.interval = M.interval - 0.1
                M.t_sec = M.t_sec - 0.1
                if M.interval <= 0.1 then
                    M.interval = 0.1
                    M.t_sec = 0.1
                end
            end
            if not util.equal(M.t_sec, M.interval) then
                return
            end
            M.t_sec = 0
            next_word_in = next_word_in - 1
            if next_word_in == 0 then
                new_word = util_rain.new_word()
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
                if word_info.hl ~= hl.falling_word_typed then
                    if word_info.line > n_lines / 3 and word_info.line < n_lines * 2 / 3 then
                        word_info.hl = hl.falling_word_warning1
                    elseif word_info.line > n_lines * 2 / 3 then
                        word_info.hl = hl.falling_word_warning2
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
                if M.words_set[1].hl ~= hl.falling_word_typed then
                    M.lives = M.lives - 1
                    util_rain.update_stats(M.lives, M.word_count)
                end
                table.remove(M.words_set, 1)
            end
        end)
    )
end

return M
