-- TODO: better looks

local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")

---@class speedtyper.menu
---@field end_of_game_text string TODO: implement later
---@field round speedtyper.round
---@field round_settings_text string
local Menu = {}
Menu.__index = Menu

---@return speedtyper.menu
function Menu.new()
    local self = setmetatable({
        round = require("speedtyper.round"),
        round_settings_text = " punctuation   numbers | time   words   rain   custom | 15   30   60   120 ",
    }, Menu)
    return self
end

function Menu:display_menu()
    util.clear_buffer_text(constants.win_height, vim.g.speedtyper_bufnr)
    api.nvim_buf_set_lines(
        vim.g.speedtyper_bufnr,
        constants.menu_first_line,
        constants.menu_first_line + 1,
        false,
        {
            self.round_settings_text,
        }
    )
    self:set_keymaps()
    self:highlight_buttons()
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

---@private
---@param button string
function Menu:activate_button(button)
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
    self:highlight_buttons()

    self.round:end_round()
    self.round:start_round()
end

---@private
function Menu:set_keymaps()
    local function get_cword()
        local button = vim.fn.expand("<cword>")
        button = util.trim(button)
        self:activate_button(button)
    end
    util.set_keymaps(
        settings.keymaps.press_button,
        get_cword,
        { buffer = vim.g.speedtyper_bufnr, desc = "SpeedTyper: press button" }
    )
end

---@private
function Menu:highlight_buttons()
    api.nvim_buf_clear_namespace(
        vim.g.speedtyper_bufnr,
        vim.g.speedtyper_ns_id,
        constants.menu_first_line,
        constants.menu_first_line + 1
    )

    for _, values in pairs(settings.round) do
        for button, active in pairs(values) do
            local button_begin, button_end = string.find(self.round_settings_text, button)
            button_begin = math.max((button_begin or 1) - 1, 0)
            button_end = button_end or 0
            if active then
                api.nvim_buf_add_highlight(
                    vim.g.speedtyper_bufnr,
                    vim.g.speedtyper_ns_id,
                    "speedtyper.hl.main",
                    constants.menu_first_line,
                    button_begin,
                    button_end
                )
            else
                api.nvim_buf_add_highlight(
                    vim.g.speedtyper_bufnr,
                    vim.g.speedtyper_ns_id,
                    "speedtyper.hl.sub",
                    constants.menu_first_line,
                    button_begin,
                    button_end
                )
            end
        end
    end
end

return Menu.new()
