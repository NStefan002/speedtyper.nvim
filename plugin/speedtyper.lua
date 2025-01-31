local api = vim.api

-- initialize global variables (only once)

if vim.g.speedtyper_ns_id then
    -- already initialized
    return
end

---@type integer
vim.g.speedtyper_ns_id = api.nvim_create_namespace("Speedtyper")
---@type integer
vim.g.speedtyper_bufnr = -1
---@type integer
vim.g.speedtyper_winnr = -1

api.nvim_create_user_command("Speedtyper", function(event)
    local util = require("speedtyper.util")
    if #event.fargs > 0 then
        util.error("Command does not take arguments.")
        return
    end

    -- set random seed for the random number generator (used in some of the modules)
    math.randomseed(os.time())

    -- load settings (will be visible to all of the modules)
    local settings = require("speedtyper.settings")
    settings:load()
    settings:create_user_commands()

    -- set up highlights
    require("speedtyper.highlights"):setup()

    -- open up speedtyper window
    require("speedtyper.ui"):toggle()
end, {
    nargs = 0,
    desc = "start speedtyper",
})

api.nvim_create_user_command("SpeedtyperLog", function(event)
    local util = require("speedtyper.util")
    if #event.fargs > 0 then
        util.error("Command does not take arguments.")
    end
    require("speedtyper.logger"):display()
end, {
    nargs = 0,
    desc = "display speedtyper log",
})
