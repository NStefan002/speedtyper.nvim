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
---@field pace_cursor_speed string
---@field pace_cursor string
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
---@field reset_settings string
local Instructions = {}
Instructions.__index = Instructions

---@return SpeedTyperInstructions
function Instructions.new()
    local self = setmetatable({
        time = [[
Type as many words as you
can in the given time.
]],
        words = [[
Type the given number of
words as fast as you can.
]],
        rain = [[
    [ Coming soon! ]
Type the falling words
before they reach the bottom.
]],
        custom = [[
    [ Coming soon! ]
Provide your own text to type.
]],
        punctuation = [[
Add punctuation to the text.
]],
        numbers = [[
Add numbers to the text.
]],
        settings = [[
The game will instantly apply
your settings (no need to restart
Neovim) and settings will
be saved for future games.
]],
        total_time = [[
Total time spent typing.
]],
        wpm = [[
Total number of characters in
the correctly typed words
(including spaces), divided
by 5 and normalised to 60 seconds.
]],
        raw_wpm = [[
Total number of typed characters
(correctly or incorrectly typed),
divided by 5 and normalised to
60 seconds.
]],
        acc = [[
Total number of correctly typed
characters divided by the total
number of characters typed.
]],
        language = [[
Choose one of available languages.
]],
        theme = [[
Choose one of the predefined themes.
]],
        randomize_theme = [[
Randomly select theme before every game.
]],
        cursor_style = [[
Choose one of the predifined cursor styles.
]],
        cursor_blinking = [[
Enable/disable cursor blinking.
]],
        pace_cursor_speed = [[
Displays a second cursor that moves
at the given pace.
]],
        pace_cursor = [[
Enable/disable pace cursor.
]],
        pace_cursor_style = [[
Choose one of the predifined pace cursor styles.
]],
        pace_cursor_blinking = [[
Enable/disable pace cursor blinking.
]],
        strict_space = [[
When disabled, jump to the next word
when pressing <space>.
]],
        stop_on_error = [[
You can not continue typing until
you correct your mistake.
]],
        confidence_mode = [[
No <bspace> allowed when enabled.
]],
        indicate_typos = [[
Indicate typos.
]],
        sound_volume = [[
Select the sound volume.
]],
        sound_on_keypress = [[
Select the short sound to play
when a key is pressed.
]],
        sound_on_typo = [[
Select the short sound to play
when a typo is made.
]],
        live_progress = [[
Displays live information about
remaining time for time mode,
word count for word mode, and
remaining lives and word count for rain mode.
]],
        average_speed = [[
Show the average speed of the last
10 attempts.
]],
        average_accuracy = [[
Show the average accuracy of the last
10 attempts.
]],
        demojify = [[
If enabled, emojis will not be displayed.
]],
        show_instructions = [[
]],
        debug_mode = [[
Enable this if you want to debug
some issue. Display the log with
`:SpeedTyperLog`.
]],
        reset_settings = [[
Set settings to the default values.
**Warning:** this action can not be
undone.
]],
    }, Instructions)
    return self
end

---@param item string
function Instructions:get(item)
    return self[item:lower()] or ""
end

return Instructions:new()
