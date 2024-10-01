local api = vim.api
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperPaceCursor
---@field private line integer
---@field private col integer
---@field private line_lengths integer[]
---@field private interval number
---@field private timer uv_timer_t
---@field private extm_id integer
---@field private closing boolean
local PaceCursor = {}
PaceCursor.__index = PaceCursor

---@param line_lengths integer[]
---@return SpeedTyperPaceCursor
function PaceCursor.new(line_lengths)
    local self = setmetatable({
        line = constants.text_first_line,
        col = 0,
        interval = constants.min_to_sec
            / (settings.general.pace_cursor_speed * constants.word_length)
            * constants.sec_to_ms,
        line_lengths = line_lengths,
        timer = (vim.uv or vim.loop).new_timer(),
        closing = false,
    }, PaceCursor)
    return self
end

function PaceCursor:update_lengths(line_lengths)
    self.line_lengths = line_lengths
end

function PaceCursor:run()
    self.extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, self.line, 0, {
        virt_text = { { "0", "SpeedTyperPaceCursor" } },
        virt_text_win_col = self.col,
        priority = 150,
    })

    self.timer:start(
        0,
        self.interval,
        vim.schedule_wrap(function()
            if self.closing then
                return
            end

            api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, self.line, 0, {
                virt_text = { { " ", "SpeedTyperPaceCursor" } },
                virt_text_win_col = self.col,
                id = self.extm_id,
                priority = 150,
            })
            self.col = self.col + 1
            if self.col == self.line_lengths[self.line - constants.text_first_line + 1] then
                self.col = 0
                self.line = self.line + 1
                self.line =
                    math.min(self.line, constants.text_num_lines + constants.text_first_line - 1)
            end
        end)
    )
end

function PaceCursor:stop()
    self.closing = true
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
end

return PaceCursor
