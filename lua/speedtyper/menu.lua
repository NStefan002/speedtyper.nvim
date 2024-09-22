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
local Menu = {}
Menu.__index = Menu

---@return SpeedTyperMenu
function Menu.new()
    local self = setmetatable({
        round = require("speedtyper.round"),
    }, Menu)

    self.round_settings_text =
        " punctuation   numbers | time   words   rain   custom | 15   30   60   120 "

    return self
end

function Menu:display_menu()
    util.clear_buffer_text(constants.win_height, globals.bufnr)
    self.settings_menu_active = false
    api.nvim_buf_set_lines(
        globals.bufnr,
        constants.menu_first_line,
        constants.menu_first_line + 1,
        false,
        {
            self.round_settings_text,
        }
    )
    local settings_info = " :SpeedTyperSettings <option> <value>"
    api.nvim_buf_set_lines(globals.bufnr, -2, -1, false, {
        settings_info,
    })
    api.nvim_buf_add_highlight(
        globals.bufnr,
        globals.ns_id,
        "SpeedTyperInfo",
        constants.win_height - 1,
        0,
        #settings_info
    )
    self:_set_keymaps()
    self:_highlight_buttons()
    self.round:set_game_mode()
    self.round:start_round()
end

function Menu:exit_menu()
    if self.round then
        self.round:end_round()
    end
end

---@return integer
function Menu:get_width()
    return #self.round_settings_text
end

---@param button string
function Menu:_activate_button(button)
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
        self:_activate_button(button)
    end
    util.set_keymaps(
        settings.keymaps.press_button,
        get_cword,
        { buffer = globals.bufnr, desc = "SpeedTyper: press button" }
    )
end

function Menu:_highlight_buttons()
    api.nvim_buf_clear_namespace(
        globals.bufnr,
        globals.ns_id,
        constants.menu_first_line,
        constants.menu_first_line + 1
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
                    constants.menu_first_line,
                    button_begin,
                    button_end
                )
            else
                api.nvim_buf_add_highlight(
                    globals.bufnr,
                    globals.ns_id,
                    "SpeedTyperButtonInactive",
                    constants.menu_first_line,
                    button_begin,
                    button_end
                )
            end
        end
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
