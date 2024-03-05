local Util = require("speedtyper.util")
local Position = require("speedtyper.position")

---@class SpeedTyperTyposTracker
---@field ns_id integer
---@field bufnr integer
---@field typos Position[]
local TyposTracker = {}
TyposTracker.__index = TyposTracker

---@param bufnr integer
function TyposTracker.new(bufnr)
    local self = {
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        typos = {},
        bufnr = bufnr,
    }
    return setmetatable(self, TyposTracker)
end

---@param should_be string
---@return boolean
function TyposTracker:check_curr_char(should_be)
    local line, col = Util.get_cursor_pos()
    if col == 0 then
        return true
    end
    local typed = vim.api.nvim_buf_get_text(self.bufnr, line, col - 1, line, col, {})[1]
    if typed ~= should_be then
        self.typos = self.typos or {}
        table.insert(self.typos, Position.new(line, col))
        self:_mark_typo(line, col)
        return false
    end
    Util.remove_element(self.typos, Position.new(line, col))
    return true
end

---@param line integer
---@param col integer
function TyposTracker:_mark_typo(line, col)
    vim.api.nvim_buf_add_highlight(
        self.bufnr,
        self.ns_id,
        "SpeedTyperTextError",
        line,
        col - 1,
        col
    )
end

function TyposTracker:redraw()
    for _, pos in ipairs(self.typos) do
        self:_mark_typo(pos.line, pos.col)
    end
end

return TyposTracker
