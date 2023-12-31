local M = {}
local api = vim.api
local ns_id = api.nvim_get_namespaces()["Speedtyper"]
local stats = require("speedtyper.stats")
local stopwatch_util = require("speedtyper.game_modes.stopwatch.util")
local util = require("speedtyper.util")
local typo = require("speedtyper.typo")
local config = require("speedtyper.config")
local opts = config.opts.game_modes.stopwatch
local n_lines = config.opts.window.height
local hl = config.opts.highlights

M.timer = nil
---@type number
M.total_time_sec = 0
---@type integer
M.num_of_typos = 0
---@type integer
M.num_of_keypresses = 0

function M.start()
    -- clear data for next game
    M.num_of_keypresses = 0
    M.num_of_typos = 0
    M.total_time_sec = 0
    M.timer = nil
    stopwatch_util.sentence = nil
    stopwatch_util.text = {}

    local extm_ids, lines = stopwatch_util.generate_extmarks()
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperStopwatch", { clear = true }),
        buffer = 0,
        callback = function()
            local curr_char = typo.check_curr_char(lines)
            if curr_char.typo_found then
                table.insert(typos, curr_char.typo_pos)
            else
                typo.remove_typo(typos, curr_char.typo_pos)
            end
            M.num_of_typos = #typos
            M.num_of_keypresses = M.num_of_keypresses + 1
            extm_ids, lines = stopwatch_util.update_extmarks(lines, extm_ids)
        end,
        desc = "Update extmarks and mark mistakes while typing.",
    })
    M.create_timer()
end

---@param ok boolean did the user force stop the game before it ended (do not show stats if game is exited prematurely)
function M.stop(ok)
    if ok then
        stats.display_stats(
          M.num_of_keypresses,
          M.num_of_typos,
          M.total_time_sec,
          0,  -- text_length
          stopwatch_util.text
        )
        util.disable_modifying_buffer()
    elseif M.timer ~= nil then
        util.info("You have left the game. Exiting...")
    end
    if M.timer then
        M.timer:stop()
        M.timer:close()
        M.timer = nil
    end
    pcall(api.nvim_del_augroup_by_name, "SpeedtyperStopwatch")
    config.restore_opts()
end

function M.create_timer()
    M.timer = (vim.uv or vim.loop).new_timer()
    local extm_id = api.nvim_buf_set_extmark(0, ns_id, n_lines - 1, 0, {
        virt_text = {
            { "Press 'i' to start the game.", "DiagnosticOk" },
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
        extm_id = api.nvim_buf_set_extmark(0, ns_id, n_lines - 1, 0, {
            virt_text = {
                { string.format("󱑆 %.1f    ", M.total_time_sec), hl.clock },
            },
            virt_text_pos = "right_align",
        })
    end

    M.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            M.total_time_sec = M.total_time_sec + 0.1
            if not opts.hide_time then
                extm_id = api.nvim_buf_set_extmark(0, ns_id, n_lines - 1, 0, {
                    virt_text = {
                        { string.format("󱑆 %.1f    ", M.total_time_sec), hl.clock },
                    },
                    virt_text_pos = "right_align",
                    id = extm_id,
                })
            end
        end)
    )
end

return M
