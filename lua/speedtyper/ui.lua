local api = vim.api
local util = require("speedtyper.util")
local constants = require("speedtyper.constants")
local globals = require("speedtyper.globals")

---@class SpeedTyperUI
---@field active boolean
---@field menu SpeedTyperMenu
---@field hover SpeedTyperHover
local UI = {}
UI.__index = UI

---@return SpeedTyperUI
function UI.new()
    local self = {
        active = false,
        menu = require("speedtyper.menu"),
        hover = require("speedtyper.hover"),
    }
    return setmetatable(self, UI)
end

function UI:_create_autocmds()
    local autocmd = api.nvim_create_autocmd
    local augroup = api.nvim_create_augroup
    local grp = augroup("SpeedTyperUI", {})

    -- TODO: add vim/window resize autocommands

    autocmd("WinClosed", {
        group = grp,
        callback = function(ev)
            if ev.match == tostring(globals.winnr) then
                require("speedtyper.settings"):save()
                self:_close()
            end
        end,
        desc = "Internally close the SpeedTyper when its gets closed.",
    })
    -- autocmd({ "BufLeave", "BufDelete", "BufWinLeave" }, {
    --     group = grp,
    --     buffer = globals.bufnr,
    --     callback = function()
    --         require("speedtyper.settings"):save()
    --         self:_close()
    --     end,
    --     desc = "Close SpeedTyper window when leaving buffer (to update the ui internal state)",
    -- })
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
        if nvim_uis[1].height <= constants._win_height or nvim_uis[1].width <= width then
            util.error("Increase the size of your Neovim instance.")
        end
    end
    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight
    local bufnr = api.nvim_create_buf(false, true)
    local winnr = api.nvim_open_win(bufnr, true, {
        relative = "editor",
        anchor = "NW",
        title = "SpeedTyper",
        row = math.floor((lines - constants._win_height) / 2),
        col = math.floor((cols - width) / 2),
        width = width,
        height = constants._win_height,
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

    api.nvim_win_set_hl_ns(globals.winnr, globals.ns_id)
    self:_set_options()
    self._disable_cmp()
    self:_create_autocmds()
    util.clear_buffer_text(10, globals.bufnr)
    self.menu:display_menu()
    self.hover:set_keymaps()
    api.nvim_set_option_value("modifiable", false, { buf = globals.bufnr })
end

function UI:_close()
    if not self.active then
        return
    end

    if globals.bufnr ~= nil and api.nvim_buf_is_valid(globals.bufnr) then
        api.nvim_buf_delete(globals.bufnr, { force = true })
    end

    if globals.winnr ~= nil and api.nvim_win_is_valid(globals.winnr) then
        api.nvim_win_close(globals.winnr, true)
    end
    globals.bufnr = -1
    globals.winnr = nil
    self.active = false
    self.menu:exit_menu()
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperUI")
    self._enable_cmp()
end

function UI:toggle()
    if self.active then
        self:_close()
    else
        self:_open()
    end
end

function UI:_set_options()
    api.nvim_set_option_value("filetype", "speedtyper", { buf = globals.bufnr })
    vim.wo[globals.winnr].wrap = false
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
