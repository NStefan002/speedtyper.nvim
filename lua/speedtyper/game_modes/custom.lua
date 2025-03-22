local api = vim.api
local util = require("speedtyper.util")
local pace_cursor = require("speedtyper.pace_cursor")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class speedtyper.game_mode.custom : speedtyper.game_mode
local Custom = require("speedtyper.game_modes._game_mode"):new()
Custom.__index = Custom

---@private
function Custom:init()
    self:reset_values()
    self:set_extmarks()

    logger:log("waiting for the user to paste the text")
    local on_lines_detach = false
    api.nvim_buf_attach(vim.g.speedtyper_bufnr, false, {
        on_lines = function(...)
            -- if the game is closing/user changes to different game mode, then return true to detach from the buffer
            if
                not util.speedtyper_is_active()
                or on_lines_detach
                or not settings.round.game_mode["custom"]
            then
                logger:log("stop waiting for the user to paste the text")
                return true
            end
            on_lines_detach = true

            local ev = { ... }
            ---@type on_lines_args
            local args = {
                type = ev[1],
                buf_handle = ev[2],
                changetick = ev[3],
                line_start = ev[4],
                line_end = ev[5],
                range_end = ev[6],
                byte_count = ev[7],
                deleted_codepoints = ev[8],
                deleted_codeunits = ev[9],
            }

            vim.schedule(function()
                local line_start, line_end = args.line_start, args.range_end
                ---text that user pasted
                local text = table.concat(
                    api.nvim_buf_get_lines(vim.g.speedtyper_bufnr, line_start, line_end, false),
                    " "
                )
                local words = util.split(text, " ")
                self.text_generator:use_custom_words(words)
                local win_width = api.nvim_win_get_width(vim.g.speedtyper_winnr)
                self.text = self.text_generator:generate_n_words_text(win_width, #words)
                self.number_of_words = #words

                self.pace_cursor = pace_cursor.new(vim.iter(self.text)
                    :map(function(line)
                        return #line
                    end)
                    :totable())

                util.clear_buffer_text(constants.win_height, vim.g.speedtyper_bufnr)
                self:set_extmarks()
                util.set_cursor_pos(constants.text_first_line + 1, 0)
                api.nvim_set_option_value("modifiable", false, { buf = vim.g.speedtyper_bufnr })
                self:set_keymaps()
            end)

            logger:log("text pasted")
            -- return true to detach from the buffer
            return true
        end,
    })

    logger:log("custom game mode started")
end

---@private
function Custom:reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        vim.g.speedtyper_bufnr,
        vim.g.speedtyper_ns_id,
        constants.info_line,
        constants.text_first_line + constants.text_num_lines + 1
    )
    self.extm_ids = {}
    self.text = { "Paste your text here." }
    self.time_sec = 0
    self.pace_cursor = nil
    self.stats:reset()
    self.ignore_next_change = true
end

---@private
---@return string
function Custom:live_progress_text()
    if not settings:get_selected("live_progress") then
        return ""
    end

    local word_count_text = settings:get_selected("demojify") and "Word count: " or "󱀽 "
    local timer_text = settings:get_selected("demojify") and "Time: " or "󱑆 "
    return util.center_text(
        ("%s%4d / %4d        %s%4.2f"):format(
            word_count_text,
            self.word_count,
            self.number_of_words,
            timer_text,
            self.time_sec
        ),
        api.nvim_win_get_width(vim.g.speedtyper_winnr)
    )
end

---@private
function Custom:start_timer()
    if not self.timer then
        self.timer = vim.uv.new_timer()
    end
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.1
            self:update_info_line(self:live_progress_text())
        end)
    )
end

return Custom:new()
