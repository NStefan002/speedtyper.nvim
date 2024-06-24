local util = require("speedtyper.util")
local stack = require("speedtyper.stack")
local globals = require("speedtyper.globals")

---@class SpeedTyperStats
---@field wpm number
---@field raw_wpm number
---@field time number
---@field acc number
---@field length_of_correct_words integer
---@field correct_chars integer number of correctly typed characters
---@field correct_spaces integer number of correctly typed spaces
---@field typed_chars integer number of characters typed
---@field typos integer number of characters typed incorrectly
---@field typed_text SpeedTyperStack
local Stats = {}
Stats.__index = Stats

-- NOTE: typos != typed_chars - correct_chars
-- typos is the total number of characters that were typed incorrectly
-- regardless of whether they were corrected or not

function Stats.new()
    local self = setmetatable({
        wpm = 0,
        raw_wpm = 0,
        time = 0,
        acc = 0,
        correct_spaces = 0,
        length_of_correct_words = 0,
        correct_chars = 0,
        typed_chars = 0,
        typos = 0,
        typed_text = stack.new(),
    }, Stats)
    return self
end

function Stats:display_stats()
    self:_set_data()
    self:_calculate_wpm()
    self:_calculate_raw_wpm()
    self:_calculate_acc()

    util.disable_buffer_modification(globals.bufnr)
    -- TODO: set buffer text
    print(
        string.format("WPM: %.2f\n", self.wpm),
        string.format("Raw WPM: %.2f\n", self.raw_wpm),
        string.format("Accuracy: %.2f%%", self.acc)
    )
end

function Stats:reset()
    self.wpm = nil
    self.raw_wpm = nil
    self.time = nil
    self.acc = nil
    self.correct_spaces = 0
    self.length_of_correct_words = 0
    self.correct_chars = 0
    self.typed_chars = 0
    self.typos = 0
    self.typed_text:clear()
end

function Stats:_set_data()
    local typed_text = self.typed_text:get_table()
    self.typed_chars = #typed_text
    local word_len = 0
    local word_is_correct = true
    for _, x in ipairs(typed_text) do
        local char = x[1]
        local correct = x[2]
        if char == " " then
            if correct then
                self.correct_spaces = self.correct_spaces + 1
            end
            if word_is_correct then
                self.length_of_correct_words = self.length_of_correct_words + word_len
            end
            word_len = 0
        else
            word_len = word_len + 1
            if not correct then
                word_is_correct = false
            end
        end
    end
    -- check if the last word is correct
    if word_is_correct then
        self.length_of_correct_words = self.length_of_correct_words + word_len
    end
    self.correct_chars = self.length_of_correct_words + self.correct_spaces
end

function Stats:_calculate_wpm()
    local words = self.correct_chars / 5
    self.wpm = words / (self.time / 60)
end

function Stats:_calculate_raw_wpm()
    local words = self.typed_chars / 5
    self.raw_wpm = words / (self.time / 60)
end

function Stats:_calculate_acc()
    self.acc = (self.correct_chars / (self.correct_chars + self.typos)) * 100
end

return Stats
