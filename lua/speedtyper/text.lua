local Util = require("speedtyper.util")

---@class SpeedTyperText
---@field selected_lang string
---@field words string[]

local SpeedTyperText = {}
SpeedTyperText.__index = SpeedTyperText

function SpeedTyperText.new()
    local text = {
        selected_lang = "",
        words = {},
    }
    return setmetatable(text, SpeedTyperText)
end

---@return string[]
function SpeedTyperText.get_available_langs()
    return { "en", "sr" }
end

---@param lang string
function SpeedTyperText:set_lang(lang)
    if
        Util.tbl_contains(self.get_available_langs(), lang, function(a, b)
            return a == b
        end)
    then
        self.selected_lang = lang
        self.words = require("speedtyper.langs." .. lang)
        math.randomseed(os.time())
    else
        Util.error("Invalid language: " .. lang)
    end
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
    local sentence = SpeedTyperText.get_word(self)
    local word = SpeedTyperText.get_word(self)
    while #sentence + #word < usable_width do
        sentence = sentence .. " " .. word
        word = SpeedTyperText.get_word(self)
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

    local sentence = SpeedTyperText.get_word(self)
    local word = SpeedTyperText.get_word(self)
    n = n - 1

    while n > 0 do
        if #sentence + #word >= usable_width then
            table.insert(text, sentence .. " ")
            sentence = SpeedTyperText.get_word(self)
        else
            sentence = sentence .. " " .. word
        end
        n = n - 1
        word = SpeedTyperText.get_word(self)
    end

    table.insert(text, sentence .. " ")

    return text
end

return SpeedTyperText
