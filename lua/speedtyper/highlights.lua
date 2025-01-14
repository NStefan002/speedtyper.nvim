local api = vim.api
local util = require("speedtyper.util")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@class speedtyper.highlight
---@field private active_theme string
---@field private augrp integer
local Hl = {}
Hl.__index = Hl

---@return speedtyper.highlight
function Hl.new()
    local self = {
        active_theme = "",
        augrp = -1,
    }
    return setmetatable(self, Hl)
end

function Hl:setup()
    self:create_autocmds()

    local active_theme = settings:get_selected("theme")
    if active_theme == "random" then
        local all_themes = settings:get_options("themes")
        util.remove_element(all_themes, "random")
        util.remove_element(all_themes, self.active_theme)
        active_theme = all_themes[math.random(1, #all_themes)]
    end

    local ok, theme = pcall(require, ("speedtyper.themes.%s"):format(active_theme))
    if not ok then
        util.error(("Theme not found: %s"):format(active_theme))
        return
    end
    theme.setup()
    self.active_theme = active_theme

    logger:log("theme:", active_theme)
end

---@private
function Hl:create_autocmds()
    if self.augrp ~= -1 then
        return
    end

    self.augrp = api.nvim_create_augroup("SpeedTyperHighlight", {})
    api.nvim_create_autocmd("Colorscheme", {
        group = self.augrp,
        pattern = "*",
        callback = function()
            vim.schedule(function()
                self:setup()
            end)
            logger:log("Colorscheme")
        end,
    })
end

return Hl.new()
