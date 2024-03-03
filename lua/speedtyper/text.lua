---@class SpeedTyperText
---@field selected_lang string
---@field words string[]
local SpeedTyperText = {}
SpeedTyperText.__index = SpeedTyperText

function SpeedTyperText.new()
    local self = {}
    for lang, selected in pairs(vim.g.speedtyper_settings.language) do
        if selected then
            self.selected_lang = lang
            self.words = require("speedtyper.langs." .. lang)
            break
        end
    end
    return setmetatable(self, SpeedTyperText)
end

---@return string
function SpeedTyperText:get_word()
    return self.words[math.random(#self.words)]
end

---@param win_width integer
---@return string
function SpeedTyperText:generate_sentence(win_width)
    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = win_width - 2 * border_width - extra_space -- 2 * border -> left and right border
    local sentence = self:get_word()
    local word = self:get_word()
    while #sentence + #word < usable_width do
        sentence = sentence .. " " .. word
        word = self:get_word()
    end
    return sentence .. " "
end

---@param win_width integer
---@param n integer
---@return string[]
function SpeedTyperText:generate_n_words_text(win_width, n)
    local text = {}

    local border_width = 2
    local extra_space = 1 -- at the end of the sentence
    local usable_width = win_width - 2 * border_width - extra_space -- 2 * border -> left and right border

    local sentence = self:get_word()
    local word = self:get_word()
    n = n - 1

    while n > 0 do
        if #sentence + #word >= usable_width then
            table.insert(text, sentence .. " ")
            sentence = self:get_word()
        else
            sentence = sentence .. " " .. word
        end
        n = n - 1
        word = self:get_word()
    end

    table.insert(text, sentence .. " ")

    return text
end

return SpeedTyperText
