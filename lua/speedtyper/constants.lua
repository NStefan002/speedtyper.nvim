---TODO: do something about this, it's kinda stoopid

---constants used for positioning and sizing of elements,
---0-indexed, because most of the buf/win api's use 0-indexing
---@enum SpeedTyperConstants
local SpeedTyperConstants = {}

-- used in ui --
SpeedTyperConstants._win_height = 10

-- used in menu --
SpeedTyperConstants._menu_first_line = 0

-- used in countdownand stopwatch --
SpeedTyperConstants._text_first_line = SpeedTyperConstants._menu_first_line + 2

SpeedTyperConstants._text_num_lines = 3

SpeedTyperConstants._text_middle_line = math.floor(
    (SpeedTyperConstants._text_first_line + SpeedTyperConstants._text_num_lines) / 2
) + 1

SpeedTyperConstants._info_line = SpeedTyperConstants._text_first_line
    + SpeedTyperConstants._text_num_lines
    + 2

SpeedTyperConstants.settings_window_height_percentage = 0.8
-- not needed
-- SpeedTyperConstants.settings_window_width_percentage = 0.4

return SpeedTyperConstants
