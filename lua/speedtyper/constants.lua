---TODO: do something about this, it's kinda stoopid

---constants used for positioning and sizing of elements,
---0-indexed, because most of the buf/win api's use 0-indexing
---@class SpeedTyperConstants
local SpeedTyperConstants = {}

-- used in ui --
SpeedTyperConstants.win_height = 10

-- used in menu --
SpeedTyperConstants.menu_first_line = 0

-- used in countdownand stopwatch --
SpeedTyperConstants.text_first_line = SpeedTyperConstants.menu_first_line + 3

SpeedTyperConstants.text_num_lines = 3

SpeedTyperConstants.text_middle_line = math.floor(
    (SpeedTyperConstants.text_first_line + SpeedTyperConstants.text_num_lines) / 2
) + 1

SpeedTyperConstants.stats_line = SpeedTyperConstants.text_first_line
    + SpeedTyperConstants.text_num_lines
    + 2

SpeedTyperConstants.info_line = SpeedTyperConstants.text_first_line - 1

-- for calculating different things --
SpeedTyperConstants.min_to_sec = 60

SpeedTyperConstants.sec_to_ms = 1000

SpeedTyperConstants.word_length = 5

return SpeedTyperConstants
