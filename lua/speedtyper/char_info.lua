---@class SpeedTyperCharInfo helper class for storing character information
---@field typed string character typed by the user
---@field should_be string character from the original text
---@field row integer row of the character in the speedtyper buffer
---@field col integer column of the character in the speedtyper buffer
local CharInfo = {}
CharInfo.__index = CharInfo

---@param typed string
---@param should_be string
---@param row integer
---@param col integer
---@return SpeedTyperCharInfo
function CharInfo.new(typed, should_be, row, col)
    return setmetatable({
        typed = typed,
        should_be = should_be,
        row = row,
        col = col,
    }, CharInfo)
end

function CharInfo:is_typo()
    return self.typed ~= self.should_be
end

---@param o SpeedTyperCharInfo
---@param p SpeedTyperCharInfo
---@return boolean
function CharInfo.equal(o, p)
    return o.typed == p.typed and o.should_be == p.should_be and o.row == p.row and o.col == p.col
end

function CharInfo:__eq(other)
    return self:equal(other)
end

return CharInfo
