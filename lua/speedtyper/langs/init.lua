local M = {}
local util = require("speedtyper.util")

M.supported_options = {
    "custom", -- if custom_text option is provided
    "en",
    "sr",
}

M.lang = ""

---@param lang string
function M.set_lang(lang)
    local supported = false
    for _, l in pairs(M.supported_options) do
        if lang == l then
            supported = true
        end
    end
    if not supported then
        util.error("Language " .. lang .. " is not supported!")
    else
        M.lang = lang
    end
end

---get list of words for selected language
---@return string[]
function M.get_words()
    return require("speedtyper.langs." .. M.lang)
end

return M
