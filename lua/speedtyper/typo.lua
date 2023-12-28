local Util = require("speedtyper.util")

---@class SpeedTyperTyposTracker
---@field ns_id integer
---@field highlight string
---@field bufnr integer
---@field typos Position[]

---@class Position
---@field line integer
---@field col integer

local Position = {}

---@param line integer
---@param col integer
function Position:new(line, col)
    local pos = setmetatable({ line = line, col = col }, self)
    self.__index = self
    return pos
end

---@param o Position
---@param p Position
---@return boolean
function Position.equal(o, p)
    return o.line == p.line and o.col == p.col
end

local SpeedTyperTyposTracker = {}

---@param highlight string
---@param bufnr? integer
function SpeedTyperTyposTracker:new(highlight, bufnr)
    local typo = setmetatable({
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        typos = {},
        bufnr = bufnr or 0,
        highlight = highlight,
    }, self)
    self.__index = self
    return typo
end

---@param should_be string
function SpeedTyperTyposTracker:check_curr_char(should_be)
    if #should_be > 1 then
        return
    end
    local line, col = Util.get_cursor_pos()
    local typed = vim.api.nvim_buf_get_text(self.bufnr, line - 1, col - 1, line - 1, col, {})[1]
    if typed ~= should_be then
        self.typos = self.typos or {}
        table.insert(self.typos, Position:new(line, col))
    else
        Util.remove_element(self.typos, Position:new(line, col), function(a, b)
            return Position.equal(a, b)
        end)
    end
end

function SpeedTyperTyposTracker:mark_typo(line, col)
    vim.api.nvim_buf_add_highlight(self.bufnr, self.ns_id, self.highlight, line - 1, col - 1, col)
end

return SpeedTyperTyposTracker
