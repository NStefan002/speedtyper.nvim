local M = {}

M.lang = ""

---@param lang string
function M.set_lang(lang)
    M.lang = lang
end

---get list of words for selected language
---@return string[]
function M.get_words()
    return require("speedtyper.langs." .. M.lang)
end

return M
