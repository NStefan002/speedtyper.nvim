local Util = require("speedtyper.util")
local Round = require("speedtyper.round")

---@class SpeedTyperMenu
---@field bufnr integer
---@field ns_id integer
---@field buttons table<string, boolean>
---@field text string

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local menu = {
        bufnr = nil,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        buttons = {
            text_variant = {
                ["punctuation"] = false,
                ["numbers"] = false,
            },
            game_mode = {
                ["time"] = true,
                ["words"] = false,
                ["rain"] = false,
                ["custom"] = false,
            },
            length = {
                ["15"] = false,
                ["30"] = true,
                ["60"] = false,
                ["120"] = false,
            },
        },
        text = "punctuation  numbers | time  words  rain  custom | 15  30  60  120",
        round = nil,
    }
    return setmetatable(menu, Menu)
end

---@param bufnr integer
function Menu:display_menu(bufnr)
    self.bufnr = bufnr
    self.round = Round.new(self.bufnr)
    vim.api.nvim_buf_set_lines(self.bufnr, 0, 1, false, {
        self.text,
    })
    Menu._set_keymaps(self)
    Menu._highlight_buttons(self)
    -- default gamemode
    self.round:set_game_mode("time", self.buttons.length, self.buttons.text_variant)
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
    return #self.text
end

---@param button string
function Menu:_activate_button(button)
    button = Util.trim(button)

    -- NOTE: temporary solution
    if button == "custom" then
        return
    end

    -- find out in which group the button belongs
    if self.buttons.text_variant[button] ~= nil then
        -- both can be active at the same time
        self.buttons.text_variant[button] = not self.buttons.text_variant[button]
    elseif self.buttons.game_mode[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(self.buttons.game_mode) do
            self.buttons.game_mode[b] = false
        end
        self.buttons.game_mode[button] = true
    elseif self.buttons.length[button] ~= nil then
        -- one needs to be active at all times
        for b, _ in pairs(self.buttons.length) do
            self.buttons.length[b] = false
        end
        self.buttons.length[button] = true
    end
    self.round:end_round()
    for b, active in pairs(self.buttons.game_mode) do
        if active then
            self.round:set_game_mode(b, self.buttons.length, self.buttons.text_variant)
        end
    end
    self.round:start_round()
    Menu._highlight_buttons(self)
end

function Menu:_set_keymaps()
    local function get_cword()
        local button = vim.fn.expand("<cword>")
        ---@diagnostic disable-next-line: param-type-mismatch
        Menu._activate_button(self, button)
    end
    vim.keymap.set("n", "<2-LeftMouse>", get_cword, { buffer = true })
    vim.keymap.set("n", "<CR>", get_cword, { buffer = true })
end

function Menu:_highlight_buttons()
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, 1)

    local all_buttons = {}
    for _, button_group in pairs(self.buttons) do
        for button, active in pairs(button_group) do
            all_buttons[button] = active
        end
    end

    for button, active in pairs(all_buttons) do
        local button_begin, button_end = string.find(self.text, button)
        button_begin = button_begin - 2 or 0
        button_end = button_end or 0
        if button_begin < 0 then
            button_begin = 0
        end
        if active then
            vim.api.nvim_buf_add_highlight(
                self.bufnr,
                self.ns_id,
                "SpeedTyperButtonActive",
                0,
                button_begin,
                button_end
            )
        else
            vim.api.nvim_buf_add_highlight(
                self.bufnr,
                self.ns_id,
                "SpeedTyperButtonInactive",
                0,
                button_begin,
                button_end
            )
        end
    end
end

return Menu
