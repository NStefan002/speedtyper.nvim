local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class SpeedTyperUI
---@field private active boolean
---@field menu SpeedTyperMenu
---@field hover SpeedTyperHover
---@field private vim_opt table vim options to restore after closing Speedtyper
local UI = {}
UI.__index = UI

---@return SpeedTyperUI
function UI.new()
    local self = {
        active = false,
        menu = require("speedtyper.menu"),
        hover = require("speedtyper.hover"),
        -- TODO: is it ok like this??
        vim_opt = {},
    }
    return setmetatable(self, UI)
end

function UI:_create_autocmds()
    local autocmd = api.nvim_create_autocmd
    local augroup = api.nvim_create_augroup
    local grp = augroup("SpeedTyperUI", {})

    local schedule_close = vim.schedule_wrap(function()
        self:_close()
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
    -- TODO: FIND OUT WHY THIS DOESN'T WORK FOR UNLISTED/SCRATCH BUFFERS EVEN THOUGH THEY GET HIDDEN
    -- autocmd("BufHidden", {
    --     group = grp,
    --     -- buffer = globals.bufnr,
    --     pattern = "*",
    --     callback = function(ev)
    --         print(ev.event, ev.buf)
    --     end,
    -- })
    -- HACK: should do the same as the BufHidden autocmd, currently only opening netrw inside Speedtyper window creates problems
    -- autocmd("FileType", {
    --     group = grp,
    --     pattern = "*",
    --     callback = function(ev)
    --         --[[
    --             HACK: I guess what happens is the following: the FileType autocmd closes the window when the 'filetype' option for netrw
    --             has been set but it doesn't leave enough time for netrw to load which causes the netrw text to get 'merged' with
    --             the buffer that was active before ':SpeedTyper' (see https://github.com/NStefan002/speedtyper.nvim/issues/30).
    --             It seems like this works. I understand it, but I don't.
    --         ]]
    --         vim.schedule(function()
    --             local current_win = api.nvim_get_current_win()
    --             local current_win_buf = api.nvim_win_get_buf(current_win)
    --             if globals.winnr ~= current_win or ev.buf ~= current_win_buf then
    --                 return
    --             end
    --             if ev.buf ~= globals.bufnr and self.active then
    --                 require("speedtyper.settings"):save()
    --                 self:_close()
    --             end
    --         end)
    --     end,
    --     desc = "Close the SpeedTyper window if the user opens up netrw inside of it.",
    -- })
end

function UI:_open()
    if self.active then
        return
    end

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
        title = "SpeedTyper",
        row = math.floor((lines - constants.win_height) / 2),
        col = math.floor((cols - width) / 2),
        width = width,
        height = constants.win_height,
        style = "minimal",
        border = "double",
        noautocmd = true,
    })

    globals.bufnr = bufnr
    globals.winnr = winnr
    self.active = true

    if winnr == 0 then
        util.error("Failed to open window")
        self:_close()
    end

    logger:log("winnr:", winnr, "bufnr:", bufnr)

    api.nvim_win_set_hl_ns(globals.winnr, globals.ns_id)
    require("speedtyper.highlights").setup()
    self._disable_cmp()
    self:_create_autocmds()
    self.menu:display_menu()
    self.hover:set_keymaps()
    self:_save_options()
    self:_set_options()
end

function UI:_close()
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
    self._enable_cmp()
    self:_restore_options()

    require("speedtyper.settings"):save()
end

function UI:toggle()
    if self.active then
        self:_close()
    else
        self:_open()
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

function UI._set_options()
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

function UI:_save_options()
    self.vim_opt.guicursor = api.nvim_get_option_value("guicursor", { scope = "global" })

    logger:log("saved options:", self.vim_opt)
end

function UI:_restore_options()
    api.nvim_set_option_value("guicursor", self.vim_opt.guicursor, { scope = "global" })

    logger:log("restored options:", self.vim_opt)
end

-- NOTE: this will probably be removed and be asked of the user to do,
-- but it'll stay for now for testing purposes
function UI._disable_cmp()
    if package.loaded["cmp"] then
        -- disable cmp while playing the game
        require("cmp").setup.buffer({ enabled = false })
    end
end

function UI._enable_cmp()
    if package.loaded["cmp"] then
        -- disable cmp while playing the game
        require("cmp").setup.buffer({ enabled = true })
    end
end

return UI.new()
