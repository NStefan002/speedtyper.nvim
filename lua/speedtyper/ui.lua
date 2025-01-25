local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class speedtyper.ui
---@field menu speedtyper.menu
---@field hover speedtyper.hover
---@field private vim_opt table vim options to restore after closing Speedtyper
local UI = {}
UI.__index = UI

---@return speedtyper.ui
function UI.new()
    local self = {
        menu = require("speedtyper.menu"),
        hover = require("speedtyper.hover"),
        vim_opt = {},
    }
    return setmetatable(self, UI)
end

function UI:toggle()
    if util.speedtyper_is_active() then
        self:close()
    else
        self:open()
    end
end

function UI:redraw()
    if util.speedtyper_is_active() then
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

    autocmd("WinClosed", {
        group = grp,
        callback = function(ev)
            if ev.match == tostring(vim.g.speedtyper_winnr) then
                logger:log("WinClosed", ev)
                self:cleanup()
                if api.nvim_buf_is_valid(vim.g.speedtyper_bufnr) then
                    api.nvim_buf_delete(vim.g.speedtyper_bufnr, { force = true })
                end
                require("speedtyper.settings"):save()
            end
        end,
        desc = "Internally close the SpeedTyper when its gets closed.",
    })
    autocmd({ "BufDelete", "BufWinLeave" }, {
        group = grp,
        buffer = vim.g.speedtyper_bufnr,
        callback = function()
            logger:log("BufDelete/BufWinLeave")
            vim.schedule(function()
                self:close()
            end)
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
    local width = self.menu:get_width()
    local nvim_uis = api.nvim_list_uis()
    if #nvim_uis > 0 then
        if nvim_uis[1].height <= constants.win_height or nvim_uis[1].width <= width then
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
            { " ", "" },
            settings:get_selected("demojify") and { "", "" } or { " ", "speedtyper.hl.main" },
            { "Speed", "speedtyper.hl.text" },
            { "Typer", "speedtyper.hl.main" },
            { " ", "" },
        },
        footer = {
            { " :", "speedtyper.hl.text" },
            { "SpeedTyperSettings", "speedtyper.hl.main" },
            { " ", "" },
            { "<option>", "speedtyper.hl.sub" },
            { " ", "" },
            { "<value>", "speedtyper.hl.sub" },
            { " ", "" },
        },
        footer_pos = "center",
        row = math.floor((lines - constants.win_height) / 2),
        col = math.floor((cols - width) / 2),
        width = width,
        height = constants.win_height,
        style = "minimal",
        border = "double",
        noautocmd = true,
    })

    vim.g.speedtyper_bufnr = bufnr
    vim.g.speedtyper_winnr = winnr

    if winnr == 0 then
        util.error("Failed to open window")
        api.nvim_buf_delete(bufnr, { force = true })
        return
    end

    logger:log("winnr:", winnr, "bufnr:", bufnr)

    api.nvim_win_set_hl_ns(vim.g.speedtyper_winnr, vim.g.speedtyper_ns_id)
    require("speedtyper.highlights"):setup()
    self:create_autocmds()
    self.menu:display_menu()
    self.hover:set_keymaps()
    self:save_options()
    self:set_options()
    util.hl("NormalFloat", { link = "speedtyper.hl.bg" })
    util.hl("FloatBorder", { link = "speedtyper.hl.main" })
end

---@private
function UI:close()
    if not util.speedtyper_is_active() then
        return
    end

    if api.nvim_buf_is_valid(vim.g.speedtyper_bufnr) then
        api.nvim_buf_delete(vim.g.speedtyper_bufnr, { force = true })
    end

    if api.nvim_win_is_valid(vim.g.speedtyper_winnr) then
        api.nvim_win_close(vim.g.speedtyper_winnr, true)
    end

    self:cleanup()

    require("speedtyper.settings"):save()
end

function UI:cleanup()
    self.menu:exit_menu()
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperUI")
    self:restore_options()
end

---@private
function UI.set_options()
    api.nvim_set_option_value("modifiable", false, { buf = vim.g.speedtyper_bufnr })
    api.nvim_set_option_value("filetype", "speedtyper", { buf = vim.g.speedtyper_bufnr })
    api.nvim_set_option_value("wrap", false, { win = vim.g.speedtyper_winnr })
    local cursor_style = settings:get_selected("cursor_style")
    api.nvim_set_option_value(
        "guicursor",
        util.create_cursor(cursor_style, settings:get_selected("cursor_blinking")),
        { scope = "global" }
    )
    if settings:get_selected("confidence_mode") then
        vim.keymap.set("i", "<BS>", "<Nop>", { buffer = vim.g.speedtyper_bufnr })
        vim.keymap.set("i", "<C-w>", "<Nop>", { buffer = vim.g.speedtyper_bufnr })
        vim.keymap.set("i", "<C-u>", "<Nop>", { buffer = vim.g.speedtyper_bufnr })
        vim.keymap.set("i", "<C-h>", "<Nop>", { buffer = vim.g.speedtyper_bufnr })
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
