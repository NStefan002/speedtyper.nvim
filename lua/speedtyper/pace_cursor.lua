local api = vim.api
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperPaceCursor
---@field private line integer
---@field private col integer
---@field private line_lengths integer[]
---@field private total_len_before integer how many non-visible characters is pace_cursor behind the current first character
---@field private total_len_after integer how many non-visible characters is pace_cursor ahead of the current last character
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
        total_len_before = 0,
        total_len_after = 0,
        timer = (vim.uv or vim.loop).new_timer(),
        closing = false,
    }, PaceCursor)

    self.extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, self.line, 0, {
        virt_text = { { "", "SpeedTyperPaceCursor" } },
        virt_text_win_col = self.col,
        priority = 150,
    })

    return self
end

---@param line_lengths integer[]
function PaceCursor:move_up(line_lengths)
    local idx = self.line - constants.text_first_line + 1
    if idx <= 1 then
        self.total_len_before = self.total_len_before + self.line_lengths[1]
    elseif idx > #self.line_lengths + 1 then
        self.total_len_after = self.total_len_after - self.line_lengths[#self.line_lengths]
    else
        self.line = self.line - 1
    end
    self.line_lengths = line_lengths
end

function PaceCursor:run()
    self.timer:start(
        0,
        self.interval,
        vim.schedule_wrap(function()
            if self.closing then
                return
            end

            if self.total_len_before > 0 then
                self.total_len_before = self.total_len_before - 1
                self:_hide_cursor()
                self.col = 0
                return
            end

            if self.total_len_after > 0 then
                self.total_len_after = self.total_len_after - 1
                self:_hide_cursor()
                self.col = 0
                return
            end

            local idx = self.line - constants.text_first_line + 1
            if idx > #self.line_lengths then
                self.total_len_after = self.total_len_after + 1
                self:_hide_cursor()
                self.col = 0
                return
            end

            api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, self.line, 0, {
                virt_text = { { " ", "SpeedTyperPaceCursor" } },
                virt_text_win_col = self.col,
                id = self.extm_id,
                priority = 150,
            })

            self.col = self.col + 1
            if self.col == self.line_lengths[idx] then
                self.col = 0
                self.line = self.line + 1
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
    if self.extm_id then
        pcall(api.nvim_buf_del_extmark, globals.bufnr, globals.ns_id, self.extm_id)
        self.extm_id = nil
    end
end

function PaceCursor:_hide_cursor()
    if not self.extm_id then
        return
    end
    api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, self.line, 0, {
        virt_text = { { "", "SpeedTyperPaceCursor" } },
        virt_text_win_col = self.col,
        id = self.extm_id,
        priority = 150,
    })
end

return PaceCursor
