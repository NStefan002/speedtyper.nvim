local M = {}
local util = require("speedtyper.util")

M.available_game_modes = {
    "countdown",
    "stopwatch",
    "rain",
    -- "code_snippets",
}

M.game_mode = ""

function M.set_game_mode(game_mode)
    M.game_mode = game_mode
end

function M.start_game()
    util.info("Selected game mode: " .. M.game_mode)
    -- every game mode should have start method with no arguments
    return require("speedtyper.game_modes." .. M.game_mode).start()
end

function M.end_game()
    require("speedtyper.game_modes." .. M.game_mode).stop()
end

return M
