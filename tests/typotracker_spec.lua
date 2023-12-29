---@diagnostic disable: undefined-field, undefined-global
local Config = require("speedtyper.config")
local hl = Config.get_default_config().highlights.typo
local T = require("speedtyper.typo")
local tracker = T:new(0, hl)
local eq = assert.are.same
local normal = vim.cmd.normal

local function key(k)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(k, true, false, true), "x", true)
end
local function write(str)
    -- "a" to enter insert mode
    str = "a" .. str
    key(str)
end

describe("Typo tracker tests", function()
    before_each(function()
        require("plenary.reload").reload_module("speedtyper")
        tracker = T:new(hl, 0)
        normal("Gdgg")
    end)
    it("check current character", function()
        normal("gg0")
        write("x")
        tracker:check_curr_char("x")
        eq(#tracker.typos, 0)

        write("a")
        tracker:check_curr_char("x")
        eq(tracker.typos[1].line, 1)
        eq(tracker.typos[1].col, 2)

        write("<CR>")
        write("a")
        tracker:check_curr_char("x")
        eq(tracker.typos[2].line, 2)
        eq(tracker.typos[2].col, 1)
    end)

    it("typo corrected", function()
        normal("gg0")
        write("a")
        tracker:check_curr_char("x")
        eq(#tracker.typos, 1)

        normal("Gdgg")
        write("x")
        tracker:check_curr_char("x")
        eq(#tracker.typos, 0)
    end)
end)
