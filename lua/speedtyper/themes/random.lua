local M = {}
local settings = require("speedtyper.settings")
local util = require("speedtyper.util")

function M.setup()
    local themes = {}
    for theme, _ in pairs(settings.general.theme) do
        if theme ~= "random" then
            table.insert(themes, theme)
        end
    end
    local random_theme = themes[math.random(1, #themes)]
    require("speedtyper.themes." .. random_theme).setup()
    util.info(("Randomly selected theme: %s"):format(random_theme))
end

return M
