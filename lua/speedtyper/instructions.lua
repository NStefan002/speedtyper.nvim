---@class SpeedTyperInstructions
---@field time string
---@field words string
---@field rain string
---@field custom string
---@field punctuation string
---@field numbers string
---@field total_time string
---@field wpm string
---@field raw_wpm string
---@field acc string
local Instructions = {}
Instructions.__index = Instructions

---@param item string
function Instructions.get(item)
    return Instructions[item] or ""
end

Instructions.time = [[
Type as many words as you
can in the given time.
]]

Instructions.words = [[
Type the given number of
words as fast as you can.
]]

Instructions.rain = [[
    [ Coming soon! ]
Type the falling words
before they reach the bottom.
]]

Instructions.custom = [[
    [ Coming soon! ]
Provide your own text to type.
]]

Instructions.punctuation = [[
Add punctuation to the text.
]]

Instructions.numbers = [[
Add numbers to the text.
]]

Instructions.total_time = [[
Total time spent typing.
]]

Instructions.wpm = [[
Total number of characters in
the correctly typed words
(including spaces), divided
by 5 and normalised to 60 seconds.
]]

Instructions.raw_wpm = [[
Total number of typed characters
(correctly or incorrectly typed),
divided by 5 and normalised to
60 seconds.
]]

Instructions.acc = [[
Total number of correctly typed
characters divided by the total
number of characters typed.
]]

return Instructions
