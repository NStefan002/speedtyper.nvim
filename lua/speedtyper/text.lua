local Util = require("speedtyper.util")

---@class SpeedTyperText
---@field available_langs string[]
---@field selected_lang string
---@field words string[]

local SpeedTyperText = {
    available_langs = { "en", "sr" },
    selected_lang = nil,
    words = nil,
}

---@param lang string
function SpeedTyperText:set_lang(lang)
    if
        Util.tbl_contains(self.available_langs, lang, function(a, b)
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

---@param max_len number
---@return string
function SpeedTyperText:generate_sentence(max_len)
    local sentence = ""
    local word = self:get_word()
    while #sentence + #word < max_len do
        sentence = word .. " " .. sentence
        word = self:get_word()
    end
    return sentence
end

return SpeedTyperText
