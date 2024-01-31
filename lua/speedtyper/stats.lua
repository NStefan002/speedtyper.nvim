local Util = require("speedtyper.util")

---@class SpeedTyperStats
---@field bufnr integer
---@field ns_id integer
---@field wpm number
---@field raw_wpm number
---@field time number
---@field acc number
---@field _length_of_correct_words integer
---@field _num_of_correct_chars integer
---@field _num_of_correct_spaces integer may be used in future versions
---@field _total_chars integer

local SpeedTyperStats = {}
SpeedTyperStats.__index = SpeedTyperStats

---@param bufnr integer
function SpeedTyperStats.new(bufnr)
    local stats = {
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
    }
    return setmetatable(stats, SpeedTyperStats)
end

-- TODO: implement these functions
function SpeedTyperStats:display_stats()
    Util.disable_buffer_modification()
    SpeedTyperStats._calculate_wpm(self)
    SpeedTyperStats._calculate_raw_wpm(self)
    SpeedTyperStats._calculate_acc(self)

    -- TODO: set buffer text
    print(
        string.format("WPM: %.2f", self.wpm),
        string.format("Raw WPM: %.2f", self.raw_wpm),
        string.format("Accuracy: %.2f%%", self.acc)
    )
end

---@param time number
function SpeedTyperStats:set_time(time)
    self.time = time
end

---@param len integer
function SpeedTyperStats:set_length_of_correct_words(len)
    self._length_of_correct_words = len
end

---@param num integer
function SpeedTyperStats:set_num_of_correct_chars(num)
    self._num_of_correct_chars = num
end

---@param num integer
function SpeedTyperStats:set_num_of_correct_spaces(num)
    self._num_of_correct_spaces = num
end

---@param len integer
function SpeedTyperStats:set_total_chars(len)
    self._total_chars = len
end

function SpeedTyperStats:_calculate_wpm()
    local correct_chars = self._length_of_correct_words + self._num_of_correct_spaces
    local num_of_words = correct_chars / 5
    self.wpm = num_of_words / (self.time / 60)
end

function SpeedTyperStats:_calculate_raw_wpm()
    local num_of_words = self._total_chars / 5
    self.raw_wpm = num_of_words / (self.time / 60)
end

function SpeedTyperStats:_calculate_acc()
    self.acc = self._num_of_correct_chars / self._total_chars * 100
end

return SpeedTyperStats
