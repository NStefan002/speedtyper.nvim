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
---@field language string
---@field theme string
---@field randomize_theme string
---@field cursor_style string
---@field cursor_blinking string
---@field pace_cursor string
---@field enable_pace_cursor string
---@field pace_cursor_style string
---@field pace_cursor_blinking string
---@field strict_space string
---@field stop_on_error string
---@field confidence_mode string
---@field indicate_typos string
---@field sound_volume string
---@field sound_on_keypress string
---@field sound_on_typo string
---@field live_progress string
---@field average_speed string
---@field average_accuracy string
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

Instructions.settings = [[
The game will instantly apply
your settings (no need to restart
Neovim) and settings will
be saved for future games.
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

Instructions.language = [[
Choose one of available languages.
]]

Instructions.theme = [[
Choose one of the predefined themes.
]]

Instructions.randomize_theme = [[
Randomly select theme before every game.
]]

Instructions.cursor_style = [[
Choose one of the predifined cursor styles.
]]

Instructions.cursor_blinking = [[
Enable/disable cursor blinking.
]]

Instructions.pace_cursor = [[
Displays a second cursor that moves
at the given pace.
]]

Instructions.enable_pace_cursor = [[
Enable/disable pace cursor.
]]

Instructions.pace_cursor_style = [[
Choose one of the predifined pace cursor styles.
]]

Instructions.pace_cursor_blinking = [[
Enable/disable pace cursor blinking.
]]

Instructions.strict_space = [[
When disabled, jump to the next word
when pressing <space>.
]]

Instructions.stop_on_error = [[
You can not continue typing until
you correct your mistake.
]]

Instructions.confidence_mode = [[
No <bspace> allowed when enabled.
]]

Instructions.indicate_typos = [[
Indicate typos.
]]

Instructions.sound_volume = [[
Select the sound volume.
]]

Instructions.sound_on_keypress = [[
Select the short sound to play
when a key is pressed.
]]

Instructions.sound_on_typo = [[
Select the short sound to play
when a typo is made.
]]

Instructions.live_progress = [[
Displays live information about
remaining time for time mode,
word count for word mode, and
remaining lives and word count for rain mode.
]]

Instructions.average_speed = [[
Show the average speed of the last
10 attempts.
]]

Instructions.average_accuracy = [[
Show the average accuracy of the last
10 attempts.
]]

Instructions.debug_mode = [[
Enable this if you want to debug
some issue. Display the log with
`:SpeedTyperLog`.
]]

return Instructions
