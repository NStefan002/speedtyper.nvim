local Util = require("speedtyper.util")
local Round = require("speedtyper.round")
local constants = require("speedtyper.constants")

---@class SpeedTyperMenu
---@field bufnr integer
---@field ns_id integer
---@field end_of_game_text string TODO: implement later
---@field round SpeedTyperRound
---@field round_settings SpeedTyperRoundSettings
---@field round_settings_text string[]
---@field settings SpeedTyperSettings
---@field settings_text string[]
---@field settings_menu_active boolean
local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({
        bufnr = nil,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        round = nil,
        round_settings = vim.deepcopy(vim.g.speedtyper_round_settings),
        settings = vim.deepcopy(vim.g.speedtyper_settings),
        settings_menu_active = false,
    }, Menu)

    self.round_settings_text = {
        " punctuation   numbers | time   words   rain   custom | 15   30   60   120 ",
        " settings ",
    }

    self.settings_text = { "" }
    for setting, values in pairs(self.settings) do
        local values_text = "| "
        for value, _ in pairs(values) do
            values_text = string.format("%s%s | ", values_text, value)
        end
        table.insert(self.settings_text, self:_left_right_align(setting, values_text))
        table.insert(self.settings_text, "")
    end

    return self
end

---@param bufnr integer
function Menu:display_menu(bufnr)
    self.settings_menu_active = false
    self.bufnr = bufnr
    self.round = Round.new(self.bufnr)
    vim.api.nvim_buf_set_lines(
        self.bufnr,
        constants._menu_first_line,
        constants._menu_first_line + 1,
        false,
        {
            self.round_settings_text[1],
        }
    )
    vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, {
        self.round_settings_text[2],
    })
    self:_set_keymaps()
    self:_highlight_buttons()
    self.round:set_game_mode()
    self.round:start_round()
end

function Menu:exit_menu()
    if self.round then
        self.round:end_round()
    end
    self.round = nil
    self.bufnr = nil
end

function Menu:get_width()
    return #self.round_settings_text[1]
end

---@param button string
function Menu:_activate_button(button)
    if button == "settings" then
        self:_display_settings()
        return
    end

    -- find out in which group the button belongs
    if self.round_settings.text_variant[button] ~= nil then
        -- both can be active at the same time
        self.round_settings.text_variant[button] = not self.round_settings.text_variant[button]
    elseif self.round_settings.game_mode[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(self.round_settings.game_mode) do
            self.round_settings.game_mode[b] = false
        end
        self.round_settings.game_mode[button] = true
    elseif self.round_settings.length[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(self.round_settings.length) do
            self.round_settings.length[b] = false
        end
        self.round_settings.length[button] = true
    end
    vim.g.speedtyper_round_settings = self.round_settings
    self:_highlight_buttons()

    self.round:end_round()
    self.round:set_game_mode()
    self.round:start_round()
end

function Menu:_set_keymaps()
    local function get_cword()
        local button = vim.fn.expand("<cword>")
        button = Util.trim(button)
        if self.settings_menu_active then
            self:_activate_settings_button(button)
        else
            self:_activate_button(button)
        end
    end
    vim.keymap.set("n", "<2-LeftMouse>", get_cword, { buffer = true })
    vim.keymap.set("n", "<CR>", get_cword, { buffer = true })
end

function Menu:_highlight_buttons()
    vim.api.nvim_buf_clear_namespace(
        self.bufnr,
        self.ns_id,
        constants._menu_first_line,
        constants._menu_first_line + 1
    )

    for _, values in pairs(self.round_settings) do
        for button, active in pairs(values) do
            local button_begin, button_end = string.find(self.round_settings_text[1], button)
            button_begin = math.max((button_begin or 2) - 2, 0)
            button_end = button_end or 0
            if active then
                vim.api.nvim_buf_add_highlight(
                    self.bufnr,
                    self.ns_id,
                    "SpeedTyperButtonActive",
                    constants._menu_first_line,
                    button_begin,
                    button_end
                )
            else
                vim.api.nvim_buf_add_highlight(
                    self.bufnr,
                    self.ns_id,
                    "SpeedTyperButtonInactive",
                    constants._menu_first_line,
                    button_begin,
                    button_end
                )
            end
        end
    end
end

function Menu:_display_settings()
    self.round:end_round()
    self.settings_menu_active = true
    -- TODO: figure out wheather to resize the window or not
    local winnr = vim.api.nvim_get_current_win()
    -- local cols = vim.o.columns
    -- local lines = vim.o.lines - vim.o.cmdheight
    -- local new_height = math.min(#self.settings_text, lines)
    vim.api.nvim_win_set_config(winnr, {
        -- relative = "editor",
        -- anchor = "NW",
        title = "SpeedTyper Settings - restart the game to apply settings",
        title_pos = "center",
        -- row = math.floor((lines - new_height) / 2),
        -- col = math.floor((cols - self:get_width()) / 2),
        -- height = new_height,
    })
    vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, self.settings_text)
    for i = 1, #self.settings_text - 1, 2 do
        local setting_text = self.settings_text[i + 1]
        setting_text = Util.split(setting_text, " ")[1]
        self:_highlight_settings_buttons(setting_text, i)
    end
end

---@param button string
function Menu:_activate_settings_button(button)
    local line, _ = Util.get_cursor_pos()
    local setting_text = self.settings_text[line + 1]
    setting_text = Util.split(setting_text, " ")[1]
    local setting = self.settings[setting_text]
    if setting == nil then
        return
    end
    -- user didn't press the button or the button is already active
    if setting[button] == nil or setting[button] == true then
        return
    end
    -- activate button, and deactivate all of the others
    for b, _ in pairs(setting) do
        setting[b] = false
    end
    setting[button] = true
    vim.g.speedtyper_settings = self.settings
    self:_highlight_settings_buttons(setting_text, line)
end

---@param setting_text string
---@param line integer
function Menu:_highlight_settings_buttons(setting_text, line)
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, line, line + 1)
    local setting = self.settings[setting_text]
    for button, active in pairs(setting) do
        local button_text = string.format(" %s ", button)
        local button_begin, button_end = string.find(self.settings_text[line + 1], button_text)
        button_begin = math.max((button_begin or 1) - 1, 0)
        button_end = button_end or 0
        if active then
            vim.api.nvim_buf_add_highlight(
                self.bufnr,
                self.ns_id,
                "SpeedTyperButtonActive",
                line,
                button_begin,
                button_end
            )
        else
            vim.api.nvim_buf_add_highlight(
                self.bufnr,
                self.ns_id,
                "SpeedTyperButtonInactive",
                line,
                button_begin,
                button_end
            )
        end
    end
end

---@param text1 string
---@param text2 string
function Menu:_left_right_align(text1, text2)
    local width = self:get_width()
    local sep = string.rep(" ", width - #text1 - #text2, "")
    return string.format("%s%s%s", text1, sep, text2)
end

---@param text string
function Menu:_center_align(text)
    local width = self:get_width()
    local sep = string.rep(" ", math.floor((width - #text) / 2), "")
    return string.format("%s%s%s", sep, text, sep)
end

return Menu
