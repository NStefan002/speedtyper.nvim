local api = vim.api
local instructions = require("speedtyper.instructions")
local util = require("speedtyper.util")
local globals = require("speedtyper.globals")
local settings = require("speedtyper.settings")

---@class SpeedTyperHover
---@field bufnr integer
---@field winnr integer
---@field instruction string[]
local Hover = {}
Hover.__index = Hover

---@return SpeedTyperHover
function Hover.new()
    local self = setmetatable({
        bufnr = nil,
        winnr = nil,
        instruction = nil,
    }, Hover)
    return self
end

function Hover:set_keymaps()
    local function display_current_word_info()
        local item = vim.fn.expand("<cWORD>")
        self:_set_instruction(item)
        if #self.instruction > 0 then
            self:_open()
        end
    end
    util.set_keymaps(settings.keymaps.hover, display_current_word_info, {
        buffer = globals.bufnr,
        desc = "SpeedTyper: Display the info of the item under the cursor",
    })
end

---@param item string
function Hover:_set_instruction(item)
    self.instruction = util.split(instructions:get(item), "\n")
end

function Hover:_open()
    if self.bufnr ~= nil and self.winnr ~= nil then
        return
    end
    local n_lines = #self.instruction
    local max_len = 0
    for _, line in pairs(self.instruction) do
        max_len = math.max(max_len, #line)
    end
    local bufnr = api.nvim_create_buf(false, true)
    local winnr = api.nvim_open_win(bufnr, false, {
        relative = "cursor",
        row = 0,
        col = 1,
        width = max_len,
        height = n_lines,
        focusable = false,
        zindex = 99,
        anchor = "SW",
        style = "minimal",
        border = "single",
    })

    if winnr == 0 then
        util.error("Failed to open window")
        self:_close()
    end

    self.bufnr = bufnr
    self.winnr = winnr

    util.clear_buffer_text(n_lines, self.bufnr)
    for i, line in ipairs(self.instruction) do
        api.nvim_buf_set_lines(self.bufnr, i - 1, i, false, {
            line,
        })
    end
    self:_create_autocmds()
    api.nvim_set_option_value("filetype", "markdown", { buf = self.bufnr })
end

function Hover:_close()
    if self.bufnr ~= nil and api.nvim_buf_is_valid(self.bufnr) then
        api.nvim_buf_delete(self.bufnr, { force = true })
    end
    if self.winnr ~= nil and api.nvim_win_is_valid(self.winnr) then
        api.nvim_win_close(self.winnr, true)
    end
    self.bufnr = nil
    self.winnr = nil
    pcall(api.nvim_del_augroup_by_name, "SpeedTyperHover")
end

function Hover:_create_autocmds()
    local autocmd = api.nvim_create_autocmd
    local augroup = api.nvim_create_augroup
    local grp = augroup("SpeedTyperHover", {})

    autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = grp,
        callback = function()
            self:_close()
        end,
        desc = "Close the hover window.",
    })
end

return Hover.new()
