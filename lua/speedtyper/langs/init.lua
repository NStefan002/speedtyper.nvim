local M = {}

M.lang = ""

function M.set_lang(lang)
    M.lang = lang
end

function M.get_words()
    return require("speedtyper.langs." .. M.lang)
end

return M
