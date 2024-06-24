-- TODO: better looks

local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperMenu
---@field end_of_game_text string TODO: implement later
---@field round SpeedTyperRound
---@field round_settings_text string
---@field settings_menu_active boolean
local Menu = {}
Menu.__index = Menu

---@return SpeedTyperMenu
function Menu.new()
    local self = setmetatable({
        round = require("speedtyper.round"),
        settings_menu_active = false,
    }, Menu)

    self.round_settings_text =
        " punctuation   numbers | time   words   rain   custom | 15   30   60   120 "

    return self
end

function Menu:display_menu()
    self.settings_menu_active = false
    api.nvim_buf_set_lines(
        globals.bufnr,
        constants._menu_first_line,
        constants._menu_first_line + 1,
        false,
        {
            self.round_settings_text,
        }
    )
    api.nvim_buf_set_lines(globals.bufnr, -2, -1, false, {
        " settings",
    })
    self:_set_keymaps()
    self:_highlight_buttons()
    self.round:set_game_mode()
    self.round:start_round()
    self:_create_autocmds()
end

function Menu:exit_menu()
    if self.round then
        self.round:end_round()
    end
    self.settings_menu_active = false
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperMenu")
end

---@return integer
function Menu:get_width()
    return #self.round_settings_text
end

function Menu:_create_autocmds()
    local autocmd = api.nvim_create_autocmd
    local augroup = api.nvim_create_augroup
    local grp = augroup("SpeedTyperMenu", {})

    local last_line = 0
    autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged" }, {
        group = grp,
        callback = function()
            if not self.settings_menu_active then
                return
            end
            local line, _ = util.get_cursor_pos()
            if line % 2 == 0 then
                line = line + (line > last_line and 1 or -1)
                line = math.max(line, 1)
                line = math.min(line, api.nvim_buf_line_count(globals.bufnr) - 1)
            end
            last_line = line
            vim.schedule(function()
                -- if the menu closes (or something similar happens) before `nvim_win_set_cursor`
                if not self.settings_menu_active then
                    return
                end
                api.nvim_win_set_cursor(globals.winnr, { line + 1, 1 })
            end)
        end,
        desc = "Fix cursor to the first column when the settings menu is active.",
    })
end

---@param button string
function Menu:_activate_button(button)
    if button == "settings" then
        self:_display_settings_menu()
        return
    end

    -- find out in which group the button belongs
    if settings.round.text_variant[button] ~= nil then
        -- both can be active at the same time
        settings.round.text_variant[button] = not settings.round.text_variant[button]
    elseif settings.round.game_mode[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(settings.round.game_mode) do
            settings.round.game_mode[b] = false
        end
        settings.round.game_mode[button] = true
    elseif settings.round.length[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(settings.round.length) do
            settings.round.length[b] = false
        end
        settings.round.length[button] = true
    end
    vim.g.speedtyper_round_settings = settings.round
    self:_highlight_buttons()

    self.round:end_round()
    self.round:set_game_mode()
    self.round:start_round()
end

function Menu:_set_keymaps()
    local function get_cword()
        local button = vim.fn.expand("<cword>")
        button = util.trim(button)
        if self.settings_menu_active then
            self:_settings_button_pressed(button)
        else
            self:_activate_button(button)
        end
    end
    -- TODO: probably remove and leave to users to define
    -- vim.keymap.set("n", "<2-LeftMouse>", get_cword, { buffer = true })
    vim.keymap.set(
        "n",
        settings.keymaps.press_button,
        get_cword,
        { buffer = globals.bufnr, desc = "SpeedTyper: press button" }
    )
end

function Menu:_highlight_buttons()
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        constants._menu_first_line,
        constants._menu_first_line + 1
    )

    for _, values in pairs(settings.round) do
        for button, active in pairs(values) do
            local button_begin, button_end = string.find(self.round_settings_text, button)
            button_begin = math.max((button_begin or 2) - 2, 0)
            button_end = button_end or 0
            if active then
                api.nvim_buf_add_highlight(
                    globals.bufnr,
                    globals.ns_id,
                    "SpeedTyperButtonActive",
                    constants._menu_first_line,
                    button_begin,
                    button_end
                )
            else
                api.nvim_buf_add_highlight(
                    globals.bufnr,
                    globals.ns_id,
                    "SpeedTyperButtonInactive",
                    constants._menu_first_line,
                    button_begin,
                    button_end
                )
            end
        end
    end
end

function Menu:_display_settings_menu()
    self.round:end_round()
    self.settings_menu_active = true
    local lines = vim.o.lines - vim.o.cmdheight
    local cols = vim.o.columns
    local height = util.calc_size(constants.settings_window_height_percentage, lines)
    local width = self:get_width()
    api.nvim_win_set_config(globals.winnr, {
        relative = "editor",
        title = "SpeedTyper Settings - restart the game to apply settings",
        title_pos = "center",
        row = math.floor((lines - height) / 2),
        col = math.floor((cols - width) / 2),
        height = height,
        width = width,
    })
    self:_gen_settings_text()
    api.nvim_set_option_value("modifiable", false, { buf = globals.bufnr })
end

function Menu:_gen_settings_text()
    api.nvim_set_option_value("modifiable", true, { buf = globals.bufnr })
    local items = {
        "language",
        "theme",
        "randomize_theme",
        "cursor_style",
        "cursor_blinking",
        "enable_pace_cursor",
        "pace_cursor",
        "pace_cursor_style",
        "pace_cursor_blinking",
        "strict_space",
        "stop_on_error",
        "confidence_mode",
        "indicate_typos",
        "sound_volume",
        "sound_on_keypress",
        "sound_on_typo",
        "live_progress",
        "average_speed",
        "average_accuracy",
        "debug_mode",
    }
    local buf_lines = {}
    for _, t in ipairs(items) do
        local info = ""
        local t_settings = settings.general[t]
        if type(t_settings) == "table" then
            for k, v in pairs(t_settings) do
                if v then
                    info = ("| %s |"):format(k)
                    break
                end
            end
        elseif type(t_settings) == "number" then
            info = ("<%s>"):format(t_settings)
        elseif type(t_settings) == "boolean" then
            info = ("[%s]"):format(t_settings and "x" or " ")
        end
        table.insert(buf_lines, "  ")
        table.insert(buf_lines, self:_left_right_align(t, info))
    end
    api.nvim_buf_set_lines(globals.bufnr, 0, -1, false, buf_lines)
end

---@param button string
function Menu:_settings_button_pressed(button)
    local t_settings = settings.general[button]
    if type(t_settings) == "table" then
        local items = {}
        for k, _ in pairs(t_settings) do
            table.insert(items, k)
        end
        vim.ui.select(
            items,
            { prompt = ("Select %s:"):format(button), kind = button },
            function(item, _)
                if not item then
                    return
                end
                for k, _ in pairs(t_settings) do
                    settings.general[button][k] = false
                end
                settings.general[button][item] = true
                self:_gen_settings_text()
            end
        )
    elseif type(t_settings) == "number" then
        vim.ui.input({
            prompt = ("Enter a number value for %s:"):format(button),
        }, function(input)
            if not input then
                return
            end
            if not tonumber(input) then
                util.info("Input must be a number.")
                return
            end
            settings.general[button] = tonumber(input)
            self:_gen_settings_text()
        end)
    elseif type(t_settings) == "boolean" then
        settings.general[button] = not settings.general[button]
        self:_gen_settings_text()
    end
end

---@param text1 string
---@param text2 string
function Menu:_left_right_align(text1, text2)
    local width = self:get_width()
    local sep = string.rep(" ", width - #text1 - #text2 - 2, "")
    return string.format(" %s%s%s ", text1, sep, text2)
end

---@param text string
function Menu:_center_align(text)
    local width = self:get_width()
    local sep = string.rep(" ", math.floor((width - #text) / 2), "")
    return string.format("%s%s%s", sep, text, sep)
end

return Menu.new()
