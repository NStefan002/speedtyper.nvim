local api = vim.api
local util = require("speedtyper.util")
local position = require("speedtyper.position")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperCountdown
---@field private closing boolean
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field info_extm_id integer
---@field text string[]
---@field time_sec number
---@field text_generator SpeedTyperText
---@field stats SpeedTyperStats
---@field prev_cursor_pos Position
local Countdown = {}
Countdown.__index = Countdown

---@return SpeedTyperCountdown
function Countdown.new()
    local self = setmetatable({
        closing = false,
        timer = nil,
        extm_ids = {},
        info_extm_id = nil,
        text = {},
        text_generator = require("speedtyper.text"),
        stats = require("speedtyper.stats"),
        prev_cursor_pos = position.new(3, 1),
    }, Countdown)
    self:_apply_settings()
    return self
end

function Countdown:_apply_settings()
    for len, active in pairs(settings.round.length) do
        if active then
            ---@diagnostic disable-next-line: assign-type-mismatch
            self.time_sec = tonumber(len)
        end
    end
end

function Countdown:start()
    self:_apply_settings()
    self.text_generator:update_lang()
    self:_reset_values()
    local win_width = api.nvim_win_get_width(globals.winnr)
    self.text = self.text_generator:generate_n_lines_text(
        constants._text_num_lines,
        win_width,
        settings.round.text_variant.numbers,
        settings.round.text_variant.punctuation
    )
    self:_set_extmarks()
    self:_create_timer()

    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedTyperCountdown", {}),
        buffer = globals.bufnr,
        callback = function()
            self:_update_extmarks()
        end,
        desc = "Countdown game mode runner.",
    })
end

function Countdown:stop()
    self.closing = true
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    pcall(util.unset_keymaps, settings.keymaps.start_game)
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperCountdown")
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperCountdownTimer")
end

function Countdown:_reset_values()
    pcall(
        api.nvim_buf_clear_namespace,
        globals.bufnr,
        globals.ns_id,
        constants._text_first_line,
        constants._info_line + 1
    )
    self.closing = false
    self.extm_ids = {}
    self.text = {}
    self.prev_cursor_pos:update(0, 0)
    self.stats:reset()
end

function Countdown:_set_extmarks()
    self.extm_ids = {}
    for i = 1, constants._text_num_lines do
        local line = constants._text_first_line + i - 1
        local extm_id = api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, line, 0, {
            virt_text = { { self.text[i], "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
        table.insert(self.extm_ids, extm_id)
    end
end

function Countdown:_update_extmarks()
    -- TODO: rename line_idx or totally remove it
    local line, col = util.get_cursor_pos()
    local line_idx = line - constants._text_first_line + 1
    if
        line_idx > self.prev_cursor_pos.line
        or (line_idx == self.prev_cursor_pos.line and col > self.prev_cursor_pos.col)
    then
        local typed = api.nvim_buf_get_text(globals.bufnr, line, col - 1, line, col, {})[1]
        local curr_char = self.text[line_idx]:sub(col, col)

        if settings.general.strict_space and typed == " " and curr_char ~= " " then
            -- if the typed character is a space and it should not be a space, then jump to the next word (if possible)
            -- and fill the gaps with spaces and mark them as mistyped
            local next_space = string.find(self.text[line_idx], " ", col) or #self.text[line_idx]
            local spaces = string.rep(" ", next_space - col)
            local text_line = api.nvim_buf_get_lines(globals.bufnr, line, line + 1, false)[1]
            for i = col, next_space do
                self.stats:check_curr_char(" ", self.text[line_idx]:sub(i, i), line, i)
            end
            api.nvim_buf_set_lines(globals.bufnr, line, line + 1, false, { text_line .. spaces })
            util.set_cursor_pos(line + 1, next_space + 1, globals.winnr)
            self.stats:redraw_typos()
            return
        end

        self.stats:check_curr_char(typed, curr_char, line, col)
    else
        -- NOTE: pop characters if the cursor is moved to the left (by <bspace>, <C-w>, <C-u>, etc.)
        local diff = self.prev_cursor_pos.col - col
        if self.prev_cursor_pos.line > line then
            diff = 1
        end
        self.stats.text_info:pop_n(diff)
    end

    if col == #self.text[line_idx] or col - 1 == #self.text[line_idx] then
        if line_idx < self.prev_cursor_pos.line or col == self.prev_cursor_pos.col then
            vim.cmd.normal("o")
            vim.cmd.normal("k$")
            api.nvim_buf_set_extmark(
                globals.bufnr,
                globals.ns_id,
                line_idx + constants._text_first_line,
                0,
                {
                    id = self.extm_ids[line_idx + constants._text_first_line - 1],
                    virt_text = {
                        {
                            self.text[line_idx + constants._text_first_line - 1],
                            "SpeedTyperTextUntyped",
                        },
                    },
                    virt_text_win_col = 0,
                }
            )
        else
            if line_idx + constants._text_first_line - 1 == constants._text_middle_line then
                self:_move_up()
                col = 0
            else
                vim.cmd.normal("j0")
            end
        end
    end
    api.nvim_buf_set_extmark(
        globals.bufnr,
        globals.ns_id,
        line_idx + constants._text_first_line - 1,
        0,
        {
            id = self.extm_ids[line_idx],
            virt_text = {
                { self.text[line_idx]:sub(col + 1), "SpeedTyperTextUntyped" },
            },
            virt_text_win_col = col,
        }
    )

    self.prev_cursor_pos:update(line_idx, col)
end

function Countdown:_move_up()
    util.remove_element(self.text, self.text[1])
    local win_width = api.nvim_win_get_width(globals.winnr)
    table.insert(
        self.text,
        self.text_generator:generate_sentence(
            win_width,
            settings.round.text_variant.numbers,
            settings.round.text_variant.punctuation
        )
    )

    self:_set_extmarks()

    local written_lines = api.nvim_buf_get_lines(
        globals.bufnr,
        constants._text_first_line,
        constants._text_middle_line + 1,
        false
    )
    util.remove_element(written_lines, written_lines[1])
    table.insert(written_lines, "")
    api.nvim_buf_set_lines(
        globals.bufnr,
        constants._text_first_line,
        constants._text_middle_line + 1,
        false,
        written_lines
    )

    -- remove typos from the first line (because the line is removed)
    -- and move typos from the second line to the first line

    ---@type SpeedTyperCharInfo[]
    local text_info = self.stats.text_info:get_table()
    local to_remove = {}
    for _, info in ipairs(text_info) do
        if info.pos.line == constants._text_first_line then
            table.insert(to_remove, info)
        end
    end
    for _, info in ipairs(to_remove) do
        util.remove_element(text_info, info)
    end
    self.stats.text_info:clear()
    for _, info in ipairs(text_info) do
        info.pos:update(info.pos.line - 1, info.pos.col)
        self.stats.text_info:push(info)
    end
    self.stats:redraw_typos()
end

---------------------------- timer stuff ------------------------------------------

---@param text string
function Countdown:_update_live_progress(text)
    local timer_text = settings.general.demojify and "Time left: " or "󱑆 "
    self.info_extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants._info_line, 0, {
            virt_text = {
                { ("%s%s    "):format(timer_text, text), "SpeedTyperClockNormal" },
            },
            virt_text_pos = "right_align",
            id = self.info_extm_id,
        })
end

function Countdown:_create_timer()
    self.timer = (vim.uv or vim.loop).new_timer()
    local keys = type(settings.keymaps.start_game) == "table"
            ---@diagnostic disable-next-line: param-type-mismatch
            and table.concat(settings.keymaps.start_game, "/")
        or settings.keymaps.start_game
    local extm_id =
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, constants._info_line, 0, {
            virt_text = {
                {
                    ("Press %s to start the game."):format(keys),
                    "SpeedTyperTextOk",
                },
            },
            virt_text_pos = "right_align",
        })
    util.set_keymaps(settings.keymaps.start_game, function()
        api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
        vim.cmd.startinsert()
        util.set_cursor_pos(constants._text_first_line + 1, 0, globals.winnr)
        api.nvim_buf_del_extmark(globals.bufnr, globals.ns_id, extm_id)
        vim.schedule(function()
            util.clear_buffer_text(constants._win_height, globals.bufnr)
            self:_set_extmarks()
        end)
        self:_start_timer()
    end, { buffer = globals.bufnr, desc = "SpeedTyper: Start the game." })
end

function Countdown:_start_timer()
    local remaining_time = self.time_sec
    self.timer:start(
        0,
        1000,
        vim.schedule_wrap(function()
            if remaining_time <= 0 or self.closing then
                self.stats.time = self.time_sec
                self.stats:display_stats()
                self:stop()
                self.info_extm_id = api.nvim_buf_set_extmark(
                    globals.bufnr,
                    globals.ns_id,
                    constants._info_line,
                    0,
                    {
                        virt_text = {
                            { "Time's up!", "SpeedTyperClockWarning" },
                        },
                        virt_text_pos = "right_align",
                        id = self.info_extm_id,
                    }
                )
            else
                self:_update_live_progress(tostring(remaining_time))
                remaining_time = remaining_time - 1
            end
        end)
    )
end

return Countdown.new()
