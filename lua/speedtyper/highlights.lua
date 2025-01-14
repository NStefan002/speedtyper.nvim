local api = vim.api
local util = require("speedtyper.util")
local settings = require("speedtyper.settings")
local logger = require("speedtyper.logger")

---@alias speedtyper.hl_group_name
---| "speedtyper.hl.bg"
---| "speedtyper.hl.cursor"
---| "speedtyper.hl.error"
---| "speedtyper.hl.main"
---| "speedtyper.hl.sub"
---| "speedtyper.hl.text"

---@alias speedtyper.hl_group table<speedtyper.hl_group_name, vim.api.keyset.highlight>

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

    local ok, get_hl_groups = pcall(require, ("speedtyper.themes.%s"):format(active_theme))
    if not ok then
        util.error(("Theme not found: %s"):format(active_theme))
        return
    end
    self.set_highlights(get_hl_groups())
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

---@param hl_groups speedtyper.hl_group
function Hl.set_highlights(hl_groups)
    for name, val in pairs(hl_groups) do
        util.hl(name, val)
    end
end

return Hl.new()
