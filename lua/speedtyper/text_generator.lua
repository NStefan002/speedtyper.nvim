local api = vim.api
local settings = require("speedtyper.settings")
local util = require("speedtyper.util")

---@class speedtyper.text_generator
---@field selected_lang string
---@field words string[]
---@field last_word_idx integer
---@field randomize boolean
local Text = {}
Text.__index = Text

function Text.new()
    local self = setmetatable({ words = {}, last_word_idx = 0, randomize = true }, Text)
    return self
end

function Text:update_lang()
    local lang = settings:get_selected("language")
    if self.selected_lang == lang and #self.words > 0 then
        return
    end
    self.selected_lang = lang
    local file = io.open(
        ("%s/assets/languages/%s.json"):format(util.get_plugin_path(), self.selected_lang),
        "r"
    )
    if file then
        local json = file:read("*a")
        self.words = vim.json.decode(json).words or {}
        file:close()
    else
        self.words = {}
        require("speedtyper.notify").notify(
            ("Invalid language: %s"):format(self.selected_lang),
            vim.log.levels.ERROR,
            settings:get_selected("notify_method")
        )
    end
end

---@param words string[]
function Text:use_custom_words(words)
    self.words = words
    self.randomize = false
    self.last_word_idx = 0
end

function Text:reset()
    self.words = {}
    self.randomize = true
    self.last_word_idx = 0
end

---@param max_len integer
---@return string
function Text:generate_sentence(max_len)
    local border_width = 2
    local extra_space = " " -- at the end of the sentence
    local usable_width = max_len - 2 * border_width - #extra_space -- 2 * border -> left and right border
    local sentence = self:get_word()
    if sentence == "" then
        return ""
    end
    local word = self:get_word()
    while api.nvim_strwidth(sentence) + api.nvim_strwidth(word) < usable_width do
        if word == "" then
            break
        end
        sentence = ("%s%s %s"):format(sentence, self.get_punctuation(false), word)
        word = self:get_word()
    end

    if settings.round.text_variant.punctuation then
        sentence = self.capitalize_word(sentence)
    end
    return ("%s%s%s"):format(sentence, self.get_punctuation(true), extra_space)
end

---@param win_width integer
---@param n integer
---@return string[]
function Text:generate_n_words_text(win_width, n)
    if n == 0 then
        return {}
    end

    local text = {}

    local border_width = 2
    local extra_space = " " -- at the end of the sentence
    local usable_width = win_width - 2 * border_width - #extra_space -- 2 * border -> left and right border

    local sentence = self:get_word()
    if settings.round.text_variant.punctuation then
        sentence = self.capitalize_word(sentence)
    end
    local word = self:get_word()
    n = n - 1

    while n > 0 do
        if api.nvim_strwidth(sentence) + api.nvim_strwidth(word) >= usable_width then
            table.insert(text, ("%s%s%s"):format(sentence, self.get_punctuation(true), extra_space))
            sentence = word
            if settings.round.text_variant.punctuation then
                sentence = self.capitalize_word(sentence)
            end
        else
            sentence = ("%s%s %s"):format(sentence, self.get_punctuation(false), word)
        end
        word = self:get_word()
        n = n - 1
    end

    -- finish the last sentence
    table.insert(text, ("%s%s"):format(sentence, self.get_punctuation(true)))

    return text
end

---@param n_lines integer number of lines
---@param max_len integer maximum length of the line
---@return string[]
function Text:generate_n_lines_text(n_lines, max_len)
    local text = {}
    for _ = 1, n_lines do
        table.insert(text, self:generate_sentence(max_len))
    end
    return text
end

---@private
---returns a string representation of a number from range [0, 10000)
---with equal probability for 1-digit number, 2-digit number,
---3-digit number and 4-digit number
---@return string
function Text.get_number()
    local n_digits = math.random(1, 4)
    return tostring(math.random(0, 10 ^ n_digits - 1))
end

---if number modifier is active then there is 10% chance
---for this function to return the string representation
---of some number from range [0, 10000)
---@return string
function Text:get_word()
    if not self.randomize then
        self.last_word_idx = self.last_word_idx + 1
        if self.last_word_idx > #self.words then
            return ""
        end
        return self.words[self.last_word_idx]
    end
    local number = settings.round.text_variant.numbers
    if number and math.random() < 0.1 then
        return self.get_number()
    end
    return self.words[math.random(#self.words)]
end

---@private
---@param word string
---@return string
function Text.capitalize_word(word)
    return ("%s%s"):format(util.utf_sub(word, 1, 1):upper(), util.utf_sub(word, 2))
end

---@private
---if punctuation modifier is active then there is a 25% chance
---for this function to return the word+punctuation string
---@param ending boolean if true function must return an ending character
---@return string
function Text.get_punctuation(ending)
    if not settings.round.text_variant.punctuation then
        return ""
    end

    -- TODO: fine tune this (e.g. ',' should have a much bigger probability than ':' and ';')
    local ending_punct = { ".", "!", "?", "!?", "..." }
    local other_punct = { ",", ":", ";" }
    -- TODO: implement logic for surrounding_punct, for example if there is '(' then there should be ")" as well
    -- local surrounding_punct = { "'", '"', "(", ")" }

    if ending then
        return ending_punct[math.random(1, #ending_punct)]
    elseif math.random() < 0.25 then
        return other_punct[math.random(1, #other_punct)]
    else
        return ""
    end
end

return Text.new()
