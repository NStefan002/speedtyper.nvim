-- TODO:
-- - [ ] --   --
-- - [x] override all functions that you don't need
-- - [x] make the input box where the text is always centered and ajust the cursor accordingly
-- - [x] find a way to clear buf text from some line ( see util.clear_buffer_lines )
-- - [ ] progress bar that rises until the mistake is made, when it fills up, you get a life
-- - [ ] use utf-8 functions from speedtyper.util

local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")
local sounds = require("speedtyper.sounds")
local logger = require("speedtyper.logger")

---@class speedtyper.pair<T1, T2> { [1]: T1, [2]: T2 }

---@class speedtyper.rain.word_in_sight
---@field word string
---@field pos speedtyper.pair<integer, integer> (line, col)
---@field extm_id integer
---@field typed boolean
---@field match_end integer
local WIS = {}
WIS.__index = WIS

---@param word string
function WIS.new(word)
    local self = setmetatable({
        word = word,
        pos = {
            0,
            math.random(
                0,
                api.nvim_win_get_width(vim.g.speedtyper_winnr) - api.nvim_strwidth(word)
            ),
        },
        extm_id = -1,
        typed = false,
        match_end = 0,
    }, WIS)
    return self
end

---@param typed string
---@return boolean
function WIS:check(typed)
    if self.typed then
        return false
    end
    if #typed > #self.word then
        self.match_end = 0
        return false
    end
    if typed == self.word then
        self.typed = true
        self:del_extmark()
        return true
    end
    self.match_end = (self.word:sub(1, #typed) == typed) and #typed or 0
    return false
end

function WIS:set_extmark()
    self.extm_id =
        api.nvim_buf_set_extmark(vim.g.speedtyper_bufnr, vim.g.speedtyper_ns_id, self.pos[1], 0, {
            virt_text = { { self.word, "speedtyper.hl.sub" } },
            virt_text_win_col = self.pos[2],
            priority = constants.extmark_priority,
        })
end

function WIS:update_extmark()
    if self.extm_id == -1 then
        return
    end

    self.extm_id =
        api.nvim_buf_set_extmark(vim.g.speedtyper_bufnr, vim.g.speedtyper_ns_id, self.pos[1], 0, {
            virt_text = {
                { self.word:sub(1, self.match_end), "speedtyper.hl.text" },
                { self.word:sub(self.match_end + 1), "speedtyper.hl.sub" },
            },
            virt_text_win_col = self.pos[2],
            priority = constants.extmark_priority,
            id = self.extm_id,
        })
end

function WIS:del_extmark()
    if self.extm_id == -1 then
        return
    end
    api.nvim_buf_del_extmark(vim.g.speedtyper_bufnr, vim.g.speedtyper_ns_id, self.extm_id)
    self.extm_id = -1
end

---@class speedtyper.game_mode.rain : speedtyper.game_mode
---@field private lives integer
---@field private lives_extm_id integer
---@field private typed_word string
---@field private words_in_sight speedtyper.rain.word_in_sight[]
---@field private input_box_border_extm_ids integer[]
---@field private wpm integer
---@field private wpm_increase_interval integer
local Rain = require("speedtyper.game_modes._game_mode"):new({
    typed_word = "",
    lives_extm_id = nil,
    words_in_sight = {},
    input_box_border_extm_ids = {},
})
Rain.__index = Rain

---@private
function Rain:stop()
    self.enable_completion()
    self.restore_window_size()
    self.enable_completion()
    if self.timer then
        self.timer:stop()
        self.timer:close()
        self.timer = nil
    end
    pcall(util.unset_keymaps, settings.general.keymaps.start_game, vim.g.speedtyper_bufnr)

    logger:log("game mode stopped")
end

---@private
function Rain:init()
    self:reset_values()

    self.resize_window()

    self:set_keymaps()

    self:draw_input_box()

    vim.keymap.set("i", "<space>", "<nop>", { buffer = vim.g.speedtyper_bufnr })

    logger:log("rain game mode started")
end

---@private
function Rain:reset_values()
    self.lives = settings:get_selected("rain_lives")
    self.word_count = 0
    self.typed_word = ""
    self.words_in_sight = {}
    self.timer = nil
    self.ignore_next_change = true
    self.text_generator:reset()
    self.text_generator:update_lang()
    self.wpm = settings:get_selected("rain_starting_wpm")
    self.wpm_increase_interval = settings:get_selected("rain_wpm_increase_interval")
end

---@private
function Rain:set_extmarks() end

---@private
---@param add_new boolean
function Rain:update_extmarks(add_new)
    if add_new then
        for i, _ in ipairs(self.words_in_sight) do
            self.words_in_sight[i]:update_extmark()
            self.words_in_sight[i].pos[1] = self.words_in_sight[i].pos[1] + 1
        end
    else
        for i, _ in ipairs(self.words_in_sight) do
            if self.words_in_sight[i]:check(self.typed_word) then
                self.clear_box_text()
            end
            self.words_in_sight[i]:update_extmark()
        end
    end
end

---@private
---@param args on_bytes_args
function Rain:handle_typing(args)
    -- NOTE: row, col, prev_row, prev_col are zero-indexed positions in the vim's grid (or whatever it's called)
    -- so we'll be adding 1 to them to make them one-indexed because some of the functions we use require one-indexed values

    local row = args.start_row + args.new_end_row
    local col = args.new_end_row == 0 and (args.start_column + args.new_end_column)
        or args.new_end_column

    local prev_row = args.start_row + args.old_end_row
    local prev_col = args.old_end_row == 0 and (args.start_column + args.old_end_column)
        or args.old_end_column

    self:center_box_text()
    self:update_extmarks(false)
end

---@private
function Rain:live_progress_text() end

---@private
---@param text string
function Rain:update_info_line(text) end

---@private
function Rain:start_game()
    local speedtyper_win_config = api.nvim_win_get_config(vim.g.speedtyper_winnr)
    local box_width = math.floor(speedtyper_win_config.width / 2)
    local box_left_border = box_width - math.floor(box_width / 2)
    util.set_cursor_pos(speedtyper_win_config.height, box_left_border + math.floor(box_width / 2))
    self:attach_to_speedtyper_buffer()
    api.nvim_set_option_value("modifiable", true, { buf = vim.g.speedtyper_bufnr })
    vim.cmd.startinsert()
    self.disable_completion()
    self:start_timer()
    util.clear_buffer_lines(
        vim.g.speedtyper_bufnr,
        0,
        api.nvim_win_get_config(vim.g.speedtyper_winnr).height - 2
    )
end

---@private
function Rain:new_game() end

---@private
function Rain:start_timer()
    if not self.timer then
        self.timer = vim.uv.new_timer()
    end
    local time_until_wpm_increase = self.wpm_increase_interval
    self.time_sec = constants.min_to_sec / self.wpm
    self.timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            self.time_sec = self.time_sec + 0.1
            time_until_wpm_increase = time_until_wpm_increase - 0.1

            if time_until_wpm_increase < 0 then
                time_until_wpm_increase = self.wpm_increase_interval
                self.wpm = self.wpm + 1
            end

            if self.time_sec > constants.min_to_sec / self.wpm then
                -- TODO: call this func when you finish everything
                -- self:update_info_line(self:live_progress_text())

                self:add_new_word()

                self:update_extmarks(true)

                self.time_sec = self.time_sec - constants.min_to_sec / self.wpm
            end
        end)
    )
end

---@private
function Rain.resize_window()
    local speedtyper_win_config = api.nvim_win_get_config(vim.g.speedtyper_winnr)
    -- TODO: make constant for .9
    local new_height = math.floor(0.9 * (vim.o.lines - vim.o.cmdheight))
    speedtyper_win_config.height = new_height
    api.nvim_win_set_config(vim.g.speedtyper_winnr, speedtyper_win_config)
    util.clear_buffer_lines(vim.g.speedtyper_bufnr, 1, new_height)

    logger:log("rain mode changed window height to " .. speedtyper_win_config.height)
end

---@private
function Rain.restore_window_size()
    if not util.speedtyper_is_active() then
        return
    end

    local speedtyper_win_config = api.nvim_win_get_config(vim.g.speedtyper_winnr)
    speedtyper_win_config.height = constants.win_height
    api.nvim_win_set_config(vim.g.speedtyper_winnr, speedtyper_win_config)

    logger:log("rain mode restored window height")
end

---@private
function Rain:draw_input_box()
    -- "╔", "═", "╗", "║", "╝", "═", "╚", "║"
    local speedtyper_win_config = api.nvim_win_get_config(vim.g.speedtyper_winnr)
    local box_width = math.floor(speedtyper_win_config.width / 2)
    local box_left_border = box_width - math.floor(box_width / 2)

    api.nvim_buf_set_text(
        vim.g.speedtyper_bufnr,
        speedtyper_win_config.height - 1,
        0,
        speedtyper_win_config.height - 1,
        0,
        { (" "):rep(speedtyper_win_config.width - 1) }
    )

    table.insert(
        self.input_box_border_extm_ids,
        api.nvim_buf_set_extmark(
            vim.g.speedtyper_bufnr,
            vim.g.speedtyper_ns_id,
            speedtyper_win_config.height - 1,
            0,
            {
                virt_text = { { "║", "speedtyper.hl.main" } },
                virt_text_win_col = box_left_border,
                priority = constants.extmark_priority,
            }
        )
    )

    table.insert(
        self.input_box_border_extm_ids,
        api.nvim_buf_set_extmark(
            vim.g.speedtyper_bufnr,
            vim.g.speedtyper_ns_id,
            speedtyper_win_config.height - 2,
            0,
            {
                virt_text = {
                    { "╔", "speedtyper.hl.main" },
                    { ("═"):rep(box_width - 2), "speedtyper.hl.main" },
                    { "╗", "speedtyper.hl.main" },
                },
                virt_text_win_col = box_left_border,
                priority = constants.extmark_priority,
            }
        )
    )

    table.insert(
        self.input_box_border_extm_ids,
        api.nvim_buf_set_extmark(
            vim.g.speedtyper_bufnr,
            vim.g.speedtyper_ns_id,
            speedtyper_win_config.height - 1,
            0,
            {
                virt_text = { { "║", "speedtyper.hl.main" } },
                virt_text_win_col = box_left_border + box_width - 1,
                priority = constants.extmark_priority,
            }
        )
    )
end

---@private
function Rain:center_box_text()
    local box_line = api.nvim_buf_get_lines(vim.g.speedtyper_bufnr, -2, -1, false)[1]
    local box_text_start, box_text_end = box_line:find("%w+")

    if box_text_start == nil then
        return
    end

    local box_text = box_line:sub(box_text_start, box_text_end)
    self.typed_word = box_text

    local win_width = api.nvim_win_get_width(vim.g.speedtyper_winnr)
    local new_text = (" "):rep(math.floor((win_width - #box_text) / 2))
        .. box_text
        .. (" "):rep(math.floor((win_width - #box_text) / 2))

    self.ignore_next_change = true
    api.nvim_buf_set_text(vim.g.speedtyper_bufnr, -1, 0, -1, -1, { new_text })

    util.set_cursor_pos(
        api.nvim_win_get_height(vim.g.speedtyper_winnr),
        math.floor((win_width - #box_text) / 2) + #box_text
    )
end

---@private
function Rain.clear_box_text()
    local win_width = api.nvim_win_get_width(vim.g.speedtyper_winnr)
    api.nvim_buf_set_text(vim.g.speedtyper_bufnr, -1, 0, -1, -1, { (" "):rep(win_width) })
    util.set_cursor_pos(api.nvim_win_get_height(vim.g.speedtyper_winnr), math.floor(win_width / 2))
end

---@private
function Rain:add_new_word()
    if #self.words_in_sight >= api.nvim_win_get_height(vim.g.speedtyper_winnr) - 2 then
        -- remove last word
        ---@type speedtyper.rain.word_in_sight
        local wis = table.remove(self.words_in_sight, #self.words_in_sight)
        if not wis.typed then
            self.lives = self.lives - 1
        end
        wis:del_extmark()
    end
    local new_word = self.text_generator:get_word()
    local words = vim.iter(self.words_in_sight)
        :map(function(wis)
            return wis.word
        end)
        :totable()
    while util.tbl_contains(words, new_word) do
        new_word = self.text_generator:get_word()
        words = vim.iter(self.words_in_sight)
            :map(function(wis)
                return wis.word
            end)
            :totable()
    end
    local new_wis = WIS.new(new_word)
    new_wis:set_extmark()
    table.insert(self.words_in_sight, 1, new_wis)
end

return Rain:new()
