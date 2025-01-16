local api = vim.api
local util = require("speedtyper.util")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class speedtyper.ui
---@field private active boolean
---@field menu speedtyper.menu
---@field hover speedtyper.hover
---@field private vim_opt table vim options to restore after closing Speedtyper
local UI = {}
UI.__index = UI

---@return speedtyper.ui
function UI.new()
    local self = {
        active = false,
        menu = require("speedtyper.menu"),
        hover = require("speedtyper.hover"),
        vim_opt = {},
    }
    return setmetatable(self, UI)
end

function UI:toggle()
    if self.active then
        self:close()
    else
        self:open()
    end
end

function UI:redraw()
    if self.active then
        self:toggle()
        vim.schedule(function()
            self:toggle()
        end)
    end
end

---@private
function UI:create_autocmds()
    local autocmd = api.nvim_create_autocmd
    local augroup = api.nvim_create_augroup
    local grp = augroup("SpeedTyperUI", {})

    local schedule_close = vim.schedule_wrap(function()
        self:close()
    end)

    autocmd("WinClosed", {
        group = grp,
        callback = function(ev)
            if ev.match == tostring(globals.winnr) then
                logger:log("WinClosed", ev)
                schedule_close()
            end
        end,
        desc = "Internally close the SpeedTyper when its gets closed.",
    })
    autocmd({ "BufDelete", "BufWinLeave" }, {
        group = grp,
        buffer = globals.bufnr,
        callback = function()
            logger:log("BufDelete/BufWinLeave")
            schedule_close()
        end,
        desc = "Close the SpeedTyper window when leaving buffer (to update the ui internal state)",
    })
    autocmd("VimResized", {
        group = grp,
        callback = function()
            logger:log("VimResized")
            self:redraw()
        end,
        desc = "Redraw the SpeedTyper window when the user resizes the editor.",
    })
end

---@private
function UI:open()
    if self.active then
        return
    end

    local width = self.menu:get_width()
    local nvim_uis = api.nvim_list_uis()
    if #nvim_uis > 0 then
        if nvim_uis[1].height <= globals.win_height or nvim_uis[1].width <= width then
            util.error("Increase the size of your Neovim instance.")
            return
        end
    end
    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight
    local bufnr = api.nvim_create_buf(false, true)
    local winnr = api.nvim_open_win(bufnr, true, {
        relative = "editor",
        anchor = "NW",
        title = {
            settings:get_selected("demojify") and { " ", "" } or { "  ", "speedtyper.hl.main" },
            { "Speed", "speedtyper.hl.text" },
            { "Typer ", "speedtyper.hl.main" },
        },
        row = math.floor((lines - globals.win_height) / 2),
        col = math.floor((cols - width) / 2),
        width = width,
        height = globals.win_height,
        style = "minimal",
        border = "double",
        noautocmd = true,
    })

    globals.bufnr = bufnr
    globals.winnr = winnr
    self.active = true

    if winnr == 0 then
        util.error("Failed to open window")
        self:close()
    end

    logger:log("winnr:", winnr, "bufnr:", bufnr)

    api.nvim_win_set_hl_ns(globals.winnr, globals.ns_id)
    require("speedtyper.highlights"):setup()
    self:create_autocmds()
    self.menu:display_menu()
    self.hover:set_keymaps()
    self:save_options()
    self:set_options()
    util.hl("NormalFloat", { link = "speedtyper.hl.bg" })
end

---@private
function UI:close()
    if not self.active then
        return
    end
    self.active = false

    if globals.bufnr ~= -1 and api.nvim_buf_is_valid(globals.bufnr) then
        api.nvim_buf_delete(globals.bufnr, { force = true })
    end

    if globals.winnr ~= -1 and api.nvim_win_is_valid(globals.winnr) then
        api.nvim_win_close(globals.winnr, true)
    end
    globals.bufnr = -1
    globals.winnr = -1
    self.menu:exit_menu()
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperUI")
    self:restore_options()

    require("speedtyper.settings"):save()
end

---@private
function UI.set_options()
    api.nvim_set_option_value("modifiable", false, { buf = globals.bufnr })
    api.nvim_set_option_value("filetype", "speedtyper", { buf = globals.bufnr })
    api.nvim_set_option_value("wrap", false, { win = globals.winnr })
    local cursor_style = settings:get_selected("cursor_style")
    api.nvim_set_option_value(
        "guicursor",
        util.create_cursor(cursor_style, settings:get_selected("cursor_blinking")),
        { scope = "global" }
    )
    if settings:get_selected("confidence_mode") then
        vim.keymap.set("i", "<BS>", "<Nop>", { buffer = globals.bufnr })
        vim.keymap.set("i", "<C-w>", "<Nop>", { buffer = globals.bufnr })
        vim.keymap.set("i", "<C-u>", "<Nop>", { buffer = globals.bufnr })
        vim.keymap.set("i", "<C-h>", "<Nop>", { buffer = globals.bufnr })
    end

    logger:log("set options")
end

---@private
function UI:save_options()
    self.vim_opt.guicursor = api.nvim_get_option_value("guicursor", { scope = "global" })

    logger:log("saved options:", self.vim_opt)
end

---@private
function UI:restore_options()
    api.nvim_set_option_value("guicursor", self.vim_opt.guicursor, { scope = "global" })

    logger:log("restored options:", self.vim_opt)
end

return UI.new()
