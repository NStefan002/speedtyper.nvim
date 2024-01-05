---helper class for storing a different currsor/word/char positions
---@class Position
---@field line integer
---@field col integer

local Position = {}
Position.__index = Position

---@param line integer
---@param col integer
function Position.new(line, col)
    local pos = { line = line, col = col }
    return setmetatable(pos, Position)
end

---@param new_line integer
---@param new_col integer
function Position:update(new_line, new_col)
    self.line = new_line
    self.col = new_col
end

---@param o Position
---@param p Position
---@return boolean
function Position.equal(o, p)
    return o.line == p.line and o.col == p.col
end

function Position:__eq(other)
    return Position.equal(self, other)
end

return Position
