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
function Text._get_number()
    local n_digits = math.random(1, 4)
    return tostring(math.random(0, 10 ^ n_digits - 1))
end

---if number modifier is active then there is 10% chance
---for this function to return the string representation
---of some number from range [0, 10000)
---@return string
function Text:get_word()
    local number = settings.round.text_variant.numbers
    if number and math.random() < 0.1 then
        return self._get_number()
    end
    return self.words[math.random(#self.words)]
end

---@param word string
---@return string
function Text._capitalize_word(word)
    return ("%s%s"):format(word:sub(1, 1):upper(), word:sub(2, #word))
end

---if punctuation modifier is active then there is a 25% chance
---for this function to return the word+punctuation string
---@param ending boolean if true function must return an ending character
---@return string
function Text._get_punctuation(ending)
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

---@param max_len integer
---@return string
function Text:generate_sentence(max_len)
    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = max_len - 2 * border_width - extra_space -- 2 * border -> left and right border
    local sentence = self:get_word()
    local word = self:get_word()
    while #sentence + #word < usable_width do
        sentence = ("%s%s %s"):format(sentence, self._get_punctuation(false), word)
        word = self:get_word()
    end

    if settings.round.text_variant.punctuation then
        sentence = self._capitalize_word(sentence)
    end
    return ("%s%s%s"):format(sentence, self._get_punctuation(true), string.rep(" ", extra_space))
end

---@param win_width integer
---@param n integer
---@return string[]
function Text:generate_n_words_text(win_width, n)
    local text = {}

    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = win_width - 2 * border_width - extra_space -- 2 * border -> left and right border

    local sentence = self:get_word()
    if settings.round.text_variant.punctuation then
        sentence = self._capitalize_word(sentence)
    end
    local word = self:get_word()
    n = n - 1

    while n > 0 do
        if #sentence + #word >= usable_width then
            table.insert(
                text,
                ("%s%s%s"):format(
                    sentence,
                    self._get_punctuation(true),
                    string.rep(" ", extra_space)
                )
            )
            sentence = self:get_word()
            if settings.round.text_variant.punctuation then
                sentence = self._capitalize_word(sentence)
            end
        else
            sentence = ("%s%s %s"):format(sentence, self._get_punctuation(false), word)
        end
        n = n - 1
        word = self:get_word()
    end

    -- finish the last sentence
    table.insert(
        text,
        ("%s%s%s"):format(sentence, self._get_punctuation(true), string.rep(" ", extra_space))
    )

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

return Text.new()
