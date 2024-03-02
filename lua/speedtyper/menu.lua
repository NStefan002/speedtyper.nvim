local Util = require("speedtyper.util")
local Round = require("speedtyper.round")

---@class SpeedTyperMenu
---@field bufnr integer
---@field ns_id integer
---@field text string[]
---@field settings_text string[]
---@field end_of_game_text string TODO: implement later
---@field round SpeedTyperRound
---@field round_settings SpeedTyperRoundSettings
local Menu = {}
Menu.__index = Menu

-- TODO: finish this
function Menu.new()
    local self = {
        bufnr = nil,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        round = nil,
        round_settings = vim.deepcopy(vim.g.speedtyper_round_settings),
    }
    self.text = {
        " punctuation   numbers | time   words   rain   custom | 15   30   60   120 ",
        " settings ",
    }

    return setmetatable(self, Menu)
end

---@param bufnr integer
function Menu:display_menu(bufnr)
    self.bufnr = bufnr
    self.round = Round.new(self.bufnr)
    vim.api.nvim_buf_set_lines(self.bufnr, 0, 1, false, {
        self.text[1],
    })
    vim.api.nvim_buf_set_lines(self.bufnr, -2, -1, false, {
        self.text[2],
    })
    self:_set_keymaps()
    self:_highlight_buttons()
    -- default gamemode
    self.round:set_game_mode("time", self.round_settings.length, self.round_settings.text_variant)
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
    return #self.text[1]
end

---@param button string
function Menu:_activate_button(button)
    button = Util.trim(button)

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
    self.round:end_round()
    for b, active in pairs(self.round_settings.game_mode) do
        if active then
            self.round:set_game_mode(
                b,
                self.round_settings.length,
                self.round_settings.text_variant
            )
        end
    end
    self.round:start_round()
    self:_highlight_buttons()
    vim.g.speedtyper_round_settings = self.round_settings
end

function Menu:_set_keymaps()
    local function get_cword()
        local button = vim.fn.expand("<cword>")
        self:_activate_button(button)
    end
    vim.keymap.set("n", "<2-LeftMouse>", get_cword, { buffer = true })
    vim.keymap.set("n", "<CR>", get_cword, { buffer = true })
end

function Menu:_highlight_buttons()
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns_id, 0, 1)

    for _, values in pairs(self.round_settings) do
        for button, active in pairs(values) do
            local button_begin, button_end = string.find(self.text[1], button)
            button_begin = (button_begin or 2) - 2
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
end

return Menu
