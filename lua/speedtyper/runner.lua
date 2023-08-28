local M = {}
local api = vim.api
local config = require("speedtyper.config")
local game = require("speedtyper.game_modes")
local menu = require("speedtyper.menu")
local helper = require("speedtyper.helper")
local typo = require("speedtyper.typo")

---similar to table.remove
---@param typos table
---@param typo_pos any
local function remove_typo(typos, typo_pos)
    for i, value in ipairs(typos) do
        if value.line == typo_pos.line and value.col == typo_pos.col then
            table.remove(typos, i)
        end
    end
end

function M.start()
    M.typing()
    local opts = config.opts
    if opts.show_menu then
        menu.show()
    else
        game.start_game_mode(opts.game_mode)
    end
end

---@type integer
M.num_of_typos = 0

---@type integer
M.num_of_keypresses = 0

function M.typing()
    local extm_ids, sentences = helper.generate_extmarks()
    local typos = {}
    api.nvim_create_autocmd("CursorMovedI", {
        group = api.nvim_create_augroup("SpeedtyperTyping", { clear = true }),
        buffer = 0,
        callback = function()
            extm_ids, sentences = helper.update_extmarks(sentences, extm_ids)
            local curr_char = typo.check_curr_char(sentences)
            if curr_char.typo_found then
                table.insert(typos, curr_char.typo_pos)
            else
                remove_typo(typos, curr_char.typo_pos)
            end
            M.num_of_typos = #typos
            M.num_of_keypresses = M.num_of_keypresses + 1
        end,
        desc = "Update extmarks and mark mistakes while typing.",
    })
end

function M.stop()
    api.nvim_del_augroup_by_name("SpeedtyperTyping")
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    -- clear data for next game
    M.num_of_keypresses = 0
    M.num_of_typos = 0
end

return M
