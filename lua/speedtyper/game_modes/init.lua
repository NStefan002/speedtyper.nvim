local M = {}
local util = require("speedtyper.util")

function M.start_game_mode(game_mode)
    util.info("Selected game mode: " .. game_mode)
    -- every game mode should have start method with no arguments
    return require("speedtyper.game_modes." .. game_mode).start()
end

return M
