local position = require("speedtyper.position")

---@class SpeedTyperCharInfo helper class for storing character information
---@field typed string character typed by the user
---@field should_be string character from the original text
---@field pos Position position of the character in the speedtyper buffer
local CharInfo = {}
CharInfo.__index = CharInfo

---@param typed string
---@param should_be string
---@param line integer
---@param col integer
---@return SpeedTyperCharInfo
function CharInfo.new(typed, should_be, line, col)
    return setmetatable({
        typed = typed,
        should_be = should_be,
        pos = position.new(line, col),
    }, CharInfo)
end

function CharInfo:is_typo()
    return self.typed ~= self.should_be
end

---@param o SpeedTyperCharInfo
---@param p SpeedTyperCharInfo
---@return boolean
function CharInfo.equal(o, p)
    return o.typed == p.typed and o.should_be == p.should_be and o.pos == p.pos
end

function CharInfo:__eq(other)
    return self:equal(other)
end

return CharInfo
