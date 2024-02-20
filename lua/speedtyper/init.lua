local Ui = require("speedtyper.ui")
local Config = require("speedtyper.config")
local Highlights = require("speedtyper.highlights")
local Util = require("speedtyper.util")

---@class SpeedTyper
---@field config SpeedTyperConfig
---@field ui SpeedTyperUI
local SpeedTyper = {}
SpeedTyper.__index = SpeedTyper

---@param partial_config? SpeedTyperPartialConfig
function SpeedTyper.new(partial_config)
    local config = Config.merge_config(partial_config, Config.get_default_config())
    local self = {
        config = config,
        ui = Ui.new(),
    }
    return setmetatable(self, SpeedTyper)
end

---@param partial_config? SpeedTyperPartialConfig
function SpeedTyper.setup(partial_config)
    local speedtyper = SpeedTyper.new(partial_config)
    Highlights.setup(speedtyper.config.highlights)
    SpeedTyper._create_autocmds(speedtyper)
    SpeedTyper._create_user_commands(speedtyper)
    return speedtyper
end

function SpeedTyper:_create_autocmds()
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local grp = augroup("SpeedTyper", {})

    autocmd("Colorscheme", {
        group = grp,
        pattern = "*",
        callback = function()
            Highlights.setup(self.config.highlights)
        end,
    })
end

function SpeedTyper:_create_user_commands()
    vim.api.nvim_create_user_command("SpeedTyper", function(event)
        if #event.fargs > 0 then
            Util.error("SpeedTyper: command does not take arguments.")
        end
        self.ui:toggle()
    end, {
        nargs = 0,
        desc = "Start SpeedTyper",
    })
end

return SpeedTyper
