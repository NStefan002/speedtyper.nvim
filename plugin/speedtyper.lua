vim.api.nvim_create_user_command("SpeedTyper", function(event)
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
    require("speedtyper.highlights").setup()

    -- open up speedtyper window
    require("speedtyper.ui"):toggle()
end, {
    nargs = "*",
    desc = "Start SpeedTyper",
})

-- TODO:
-- vim.api.nvim_create_user_command("SpeedTyperLog", function(event)
--     if #event.fargs > 0 then
--         util.error("Command does not take arguments.")
--     end
--     Logger:display()
-- end, {
--     nargs = 0,
--     desc = "Display SpeedTyper Log",
-- })
