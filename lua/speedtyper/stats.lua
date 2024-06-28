local api = vim.api
local util = require("speedtyper.util")
local stack = require("speedtyper.stack")
local char_info = require("speedtyper.char_info")
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
---@field typos integer
---@field text_info SpeedTyperStack stack contains elements of type SpeedTyperCharInfo
local Stats = {}
Stats.__index = Stats

-- NOTE: typos != typed_chars - correct_chars
-- typos is the total number of characters that were typed
-- incorrectly regardless of whether they were corrected or not

---@return SpeedTyperStats
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
        text_info = stack.new(),
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
    self.text_info:clear()
end

---@param typed string
---@param should_be string
---@param line integer
---@param col integer
function Stats:check_curr_char(typed, should_be, line, col)
    if col == 0 then
        return
    end

    self.text_info:push(char_info.new(typed, should_be, line, col))
    if typed ~= should_be then
        self._mark_typo(line, col)
        self.typos = self.typos + 1
    end
end

---@return SpeedTyperCharInfo[]
function Stats:get_typos()
    return vim.tbl_filter(function(char)
        return char:is_typo()
    end, self.text_info:get_table())
end

function Stats:redraw_typos()
    local typos = self:get_typos()
    for _, info in ipairs(typos) do
        self._mark_typo(info.pos.line, info.pos.col)
    end
end

---@param line integer
---@param col integer
function Stats._mark_typo(line, col)
    api.nvim_buf_add_highlight(
        globals.bufnr,
        globals.ns_id,
        "SpeedTyperTextError",
        line,
        col - 1,
        col
    )
end

function Stats:_set_data()
    ---@type SpeedTyperCharInfo[]
    local text_info = self.text_info:get_table()
    self.typed_chars = #text_info
    local word_len = 0
    local word_is_correct = true
    for _, info in ipairs(text_info) do
        local char = info.should_be
        local correct = not info:is_typo()
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

return Stats.new()
