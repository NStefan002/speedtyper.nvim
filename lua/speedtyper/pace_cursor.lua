local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")

---@class speedtyper.pace_cursor
---@field private line integer
---@field private col integer
---@field private shape string the character that represents the cursor
---@field private line_lengths integer[]
---@field private total_len_before integer how many non-visible characters is pace_cursor behind the current first character
---@field private total_len_after integer how many non-visible characters is pace_cursor ahead of the current last character
---@field private interval number
---@field private timer uv_timer_t
---@field private extm_id integer
local PaceCursor = {}
PaceCursor.__index = PaceCursor

---@param line_lengths integer[]
---@return speedtyper.pace_cursor
function PaceCursor.new(line_lengths)
    local self = setmetatable({
        line = constants.text_first_line,
        col = 0,
        interval = constants.min_to_sec
            / (settings:get_selected("pace_cursor_speed") * constants.word_length)
            * constants.sec_to_ms,
        line_lengths = line_lengths,
        total_len_before = 0,
        total_len_after = 0,
        timer = vim.uv.new_timer(),
    }, PaceCursor)

    self.extm_id =
        api.nvim_buf_set_extmark(vim.g.speedtyper_bufnr, vim.g.speedtyper_ns_id, self.line, 0, {
            virt_text = { { "", "speedtyper.hl.cursor" } },
            virt_text_win_col = self.col,
            priority = constants.pace_cursor_extmark_priority,
        })

    while #self.line_lengths > constants.text_num_lines do
        util.remove_element(self.line_lengths, self.line_lengths[#self.line_lengths])
    end

    self.shape = self.get_cursor_char()
    self:set_hl_grp()

    return self
end

---@param line_lengths integer[]
function PaceCursor:move_up(line_lengths)
    if self.line == constants.text_first_line then
        self.total_len_before = self.total_len_before + self.line_lengths[1] - self.col
    else
        self.line = self.line - 1
    end

    if self.total_len_after > 0 then
        if #line_lengths < constants.text_num_lines then
            return
        end
        if self.total_len_after > line_lengths[#line_lengths] then
            self.total_len_after = self.total_len_after - #line_lengths[#line_lengths]
        else
            self.col = self.total_len_after
            self.line = constants.text_first_line + #line_lengths - 1
            self.total_len_after = 0
        end
    end
    self.line_lengths = line_lengths
end

function PaceCursor:run()
    if not settings:get_selected("pace_cursor") then
        return
    end

    self.timer:start(
        0,
        self.interval,
        vim.schedule_wrap(function()
            if not util.speedtyper_is_active() then
                return
            end

            if self.total_len_before > 0 then
                self.total_len_before = self.total_len_before - 1
                self:show_cursor(false)
                self.col = 0
                return
            end

            if self.total_len_after > 0 then
                self.total_len_after = self.total_len_after + 1
                self:show_cursor(false)
                self.col = 0
                return
            end

            self:show_cursor(true)

            self.col = self.col + 1
            if self.col == self.line_lengths[self.line - constants.text_first_line + 1] then
                self.col = 0
                self.line = self.line + 1
                if self.line == constants.text_first_line + #self.line_lengths then
                    self.total_len_after = 1
                    self.line = self.line - 1
                end
            end
        end)
    )
end

function PaceCursor:stop()
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    if self.extm_id then
        pcall(
            api.nvim_buf_del_extmark,
            vim.g.speedtyper_bufnr,
            vim.g.speedtyper_ns_id,
            self.extm_id
        )
        self.extm_id = nil
    end
end

---@private
---@param visible boolean
function PaceCursor:show_cursor(visible)
    if not self.extm_id then
        return
    end
    api.nvim_buf_set_extmark(vim.g.speedtyper_bufnr, vim.g.speedtyper_ns_id, self.line, 0, {
        virt_text = { { visible and self.shape or "", "speedtyper.hl.pace_cursor" } },
        virt_text_win_col = self.col,
        id = self.extm_id,
        priority = constants.pace_cursor_extmark_priority,
    })
end

---@private
---@return string
function PaceCursor.get_cursor_char()
    local style = settings:get_selected("pace_cursor_style")
    local demojify = settings:get_selected("demojify")

    if style == "block" then
        return demojify and " " or "█"
    elseif style == "underline" then
        return demojify and "_" or "▁"
    else
        return demojify and "|" or "│"
    end
end

---self.shape has to be set before calling this function
function PaceCursor:set_hl_grp()
    -- NOTE: if the pace cursor style is the same as the cursor style, then the pace cursor
    -- highlight falls back to the 'sub' highlight
    local hl_opts
    if settings:get_selected("pace_cursor_style") == settings:get_selected("cursor_style") then
        hl_opts = api.nvim_get_hl(vim.g.speedtyper_ns_id, { name = "speedtyper.hl.sub" })
    else
        hl_opts = api.nvim_get_hl(vim.g.speedtyper_ns_id, { name = "speedtyper.hl.cursor" })
    end
    -- HACK: if the pace cursor style is block, then we need both fg and bg (to make the space character look like a block)
    if self.shape == " " then
        api.nvim_set_hl(
            vim.g.speedtyper_ns_id,
            "speedtyper.hl.pace_cursor",
            { fg = hl_opts.fg, bg = hl_opts.bg }
        )
    else
        api.nvim_set_hl(vim.g.speedtyper_ns_id, "speedtyper.hl.pace_cursor", { fg = hl_opts.fg })
    end
end

return PaceCursor
