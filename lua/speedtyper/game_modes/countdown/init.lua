local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local util = require("speedtyper.util")
local countdown_util = require("speedtyper.game_modes.countdown.util")
local typo = require("speedtyper.typo")
local opts = require("speedtyper.config").opts.game_modes.countdown

M.timer = nil

---@type integer
M.num_of_typos = 0

---@type integer
M.num_of_keypresses = 0

function M.start()
    local extm_ids, sentences = countdown_util.generate_extmarks()
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperCountdown", { clear = true }),
        buffer = 0,
        callback = function()
            local curr_char = typo.check_curr_char(sentences)
            if curr_char.typo_found then
                table.insert(typos, curr_char.typo_pos)
            else
                typo.remove_typo(typos, curr_char.typo_pos)
            end
            M.num_of_typos = #typos
            M.num_of_keypresses = M.num_of_keypresses + 1
            extm_ids, sentences = countdown_util.update_extmarks(sentences, extm_ids)
        end,
        desc = "Update extmarks and mark mistakes while typing.",
    })
    M.create_timer(opts.time)
end

function M.stop()
    if M.timer then
        M.timer:stop()
        M.timer:close()
        M.timer = nil
    end
    stats.display_stats(M.num_of_keypresses, M.num_of_typos, opts.time)
    -- runner.stop()
    api.nvim_del_augroup_by_name("SpeedtyperCountdown")
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    -- clear data for next game
    M.num_of_keypresses = 0
    M.num_of_typos = 0
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
