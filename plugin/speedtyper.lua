-- You can use this loaded variable to enable conditional parts of your plugin.
if _G.SpeedtyperLoaded then
    return
end

_G.SpeedtyperLoaded = true

vim.api.nvim_create_user_command("Speedtyper", function()
    require("speedtyper").toggle()
end, {})
