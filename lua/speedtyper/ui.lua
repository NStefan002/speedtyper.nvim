local Round = require("speedtyper.round")

---@class SpeedTyperUI
---@field bufnr integer
---@field winnr integer
---@field active boolean
---@field settings SpeedTyperWindowConfig

local SpeedTyperUI = {}

---@param settings SpeedTyperWindowConfig
---@return SpeedTyperUI
function SpeedTyperUI:new(settings)
    local ui = setmetatable({
        bufnr = nil,
        winnr = nil,
        settings = settings,
    }, self)
    self.__index = self
    return ui
end

function SpeedTyperUI:_create_autocmds()
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup

    local grp = augroup("SpeedTyperGroup", {})

    autocmd({ "BufLeave", "BufDelete", "BufWinLeave" }, {
        group = grp,
        buffer = self.bufnr,
        once = true,
        callback = function()
            self:_close()
        end,
        desc = "Close SpeedTyper window when leaving buffer (to update the ui internal state)",
    })
end

---@param settings SpeedTyperWindowConfig
function SpeedTyperUI:_open(settings)
    if self.active then
        return
    end

    local cols = vim.o.columns
    local lines = vim.o.lines - vim.o.cmdheight
    local height = self.calc_size(settings.height, lines)
    local width = self.calc_size(settings.width, cols)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winnr = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        anchor = "NW",
        title = "SpeedTyper",
        row = math.floor((lines - height) / 2),
        col = math.floor((cols - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = settings.border,
        noautocmd = true,
    })

    self.bufnr = bufnr
    self.winnr = winnr
    self.active = true

    if winnr == 0 then
        print("Failed to open window")
        error("Failed to open window")
        self:_close()
    end

    self:disable()
    self:_create_autocmds()
end

function SpeedTyperUI:_close()
    if not self.active then
        return
    end

    if self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
        vim.api.nvim_buf_delete(self.bufnr, { force = true })
    end

    if self.winnr ~= nil and vim.api.nvim_win_is_valid(self.winnr) then
        vim.api.nvim_win_close(self.winnr, true)
    end
    self.bufnr = nil
    self.winnr = nil
    self.active = false
end

function SpeedTyperUI:toggle()
    if self.active then
        SpeedTyperUI:_close()
    else
        SpeedTyperUI:_open(self.settings)
    end
end

function SpeedTyperUI:disable()
    vim.wo[self.winnr].wrap = false
    if package.loaded["cmp"] then
        -- disable cmp while playing the game
        require("cmp").setup.buffer({ enabled = false })
    end
end

---calculate the dimension of the floating window
---@param size number
---@param viewport integer
function SpeedTyperUI.calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

return SpeedTyperUI
