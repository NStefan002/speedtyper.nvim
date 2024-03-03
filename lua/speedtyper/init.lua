local Ui = require("speedtyper.ui")
local Highlights = require("speedtyper.highlights")
local Util = require("speedtyper.util")

-- load settings (will be visible to all of the modules)
require("speedtyper.settings").load()

-- set random seed for the random number generator (used in some of the modules)
math.randomseed(os.time())

---@class SpeedTyper
---@field ui SpeedTyperUI
local SpeedTyper = {}
SpeedTyper.__index = SpeedTyper

function SpeedTyper.new()
    local self = {
        ui = Ui.new(),
    }
    return setmetatable(self, SpeedTyper)
end

function SpeedTyper.setup()
    local speedtyper = SpeedTyper.new()
    Highlights.setup()
    speedtyper._create_autocmds()
    speedtyper:_create_user_commands()
    return speedtyper
end

function SpeedTyper._create_autocmds()
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup
    local grp = augroup("SpeedTyper", {})

    autocmd("Colorscheme", {
        group = grp,
        pattern = "*",
        callback = function()
            Highlights.setup()
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
