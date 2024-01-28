local SpeedTyperInstructions = {}
SpeedTyperInstructions.__index = SpeedTyperInstructions

---@param item string
function SpeedTyperInstructions.get(item)
    return SpeedTyperInstructions[item] or ""
end

SpeedTyperInstructions.time = [[
Type as many words as you
can in the given time.
]]

SpeedTyperInstructions.words = [[
Type the given number of
words as fast as you can.
]]

SpeedTyperInstructions.rain = [[
    [ Coming soon! ]
Type the falling words
before they reach the bottom.
]]

SpeedTyperInstructions.custom = [[
    [ Coming soon! ]
Provide your own text to type.
]]

SpeedTyperInstructions.punctuation = [[
Add punctuation to the text.
]]

SpeedTyperInstructions.numbers = [[
Add numbers to the text.
]]

SpeedTyperInstructions.total_time = [[
Total time spent typing.
]]

SpeedTyperInstructions.wpm = [[
Total number of characters in
the correctly typed words
(including spaces), divided
by 5 and normalised to 60 seconds.
]]

SpeedTyperInstructions.raw_wpm = [[
Total number of typed characters
(correctly or incorrectly typed),
divided by 5 and normalised to
60 seconds.
]]

SpeedTyperInstructions.acc = [[
Total number of correctly typed
characters divided by the total
number of characters typed.
]]

return SpeedTyperInstructions
