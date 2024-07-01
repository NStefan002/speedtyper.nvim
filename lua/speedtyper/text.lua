local settings = require("speedtyper.settings")

---@class SpeedTyperText
---@field selected_lang string
---@field words string[]
local Text = {}
Text.__index = Text

function Text.new()
    local self = setmetatable({}, Text)
    self:update_lang()
    return self
end

function Text:update_lang()
    for lang, selected in pairs(settings.general.language) do
        if selected and self.selected_lang ~= lang then
            self.selected_lang = lang
            self.words = require(("speedtyper.langs.%s"):format(lang))
            break
        end
    end
end

---returns a string representation of a number from range [0, 10000)
---with equal probability for 1-digit number, 2-digit number,
---3-digit number and 4-digit number
---@return string
function Text.get_number()
    local n_digits = math.random(1, 4)
    return tostring(math.random(0, 10 ^ n_digits - 1))
end

---if number is true then there is 10% chance
---for this function to return the string representation
---of some number from range [0, 10000)
---@param number boolean
---@return string
function Text:get_word(number)
    if number then
        if math.random() < 0.1 then
            return self.get_number()
        end
    end
    return self.words[math.random(#self.words)]
end

---@param word string
---@return string
function Text._capitalize_word(word)
    return ("%s%s"):format(word:sub(1, 1):upper(), word:sub(2, #word))
end

---TODO:
---@param sentence string
---@return string
function Text:_add_punctuation(sentence)
    -- local sentence_ending_punct = { ".", "!", "?", "!?", "..." }
    -- local other_punct = { ",", ":", ";" }
    -- local surrounding_punct = { "'", '"' }
    return self._capitalize_word(sentence)
end

---@param max_len integer
---@param numbers boolean
---@param punctuation boolean
---@return string
function Text:generate_sentence(max_len, numbers, punctuation)
    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = max_len - 2 * border_width - extra_space -- 2 * border -> left and right border
    local sentence = self:get_word(numbers)
    local word = self:get_word(numbers)
    while #sentence + #word < usable_width do
        sentence = sentence .. " " .. word
        word = self:get_word(numbers)
    end
    if punctuation then
        return self:_add_punctuation(sentence)
    end
    return sentence .. " "
end

---@param win_width integer
---@param n integer
---@param numbers boolean
---@param punctuation boolean
---@return string[]
function Text:generate_n_words_text(win_width, n, numbers, punctuation)
    local text = {}

    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = win_width - 2 * border_width - extra_space -- 2 * border -> left and right border

    local sentence = self:get_word(numbers)
    local word = self:get_word(numbers)
    n = n - 1

    while n > 0 do
        if #sentence + #word >= usable_width then
            if punctuation then
                self:_add_punctuation(sentence)
            end
            table.insert(text, sentence .. " ")
            sentence = self:get_word(numbers)
        else
            sentence = sentence .. " " .. word
        end
        n = n - 1
        word = self:get_word(numbers)
    end

    if punctuation then
        if punctuation then
            self:_add_punctuation(sentence)
        end
        self:_add_punctuation(sentence)
    end
    table.insert(text, sentence .. " ")

    return text
end

return Text.new()
