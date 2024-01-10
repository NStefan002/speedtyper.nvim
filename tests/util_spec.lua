---@diagnostic disable: undefined-field, undefined-global
local Util = require("speedtyper.util")
local eq = assert.are.same

describe("Util test", function()
    before_each(function()
        Util = require("speedtyper.util")
    end)
    it("simulate input", function()
        Util.simulate_input("abc")
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        eq(buf_lines[1], "abc")

        Util.simulate_input("<CR>b")
        buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        eq(buf_lines[1], "abc")
        eq(buf_lines[2], "b")
    end)
    it("compare floats", function()
        eq(Util.equals(1.535453, 1.535453), true)
        eq(Util.equals(1.535453, 1.535452), false)
        eq(Util.equals(1 / 2, 2 / 4 + 0.000000000001), false)
        eq(Util.equals(1 / 3, 33 / 99), true)
        eq(Util.equals(1.0000000000, 1.00000000000), true)
    end)
    it("clear text", function()
        Util.clear_buffer_text(5)
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, line in ipairs(buf_lines) do
            if i <= 5 then
                eq(line, "")
            end
        end
    end)
    it("trim", function()
        eq(Util.trim("  a"), "a")
        eq(Util.trim("a  "), "a")
        eq(Util.trim("   a  "), "a")
        eq(Util.trim("  a ."), "a .")
    end)
    it("split", function()
        eq(Util.split("a b c"), { "a", "b", "c" })
        eq(Util.split("a:b:c", ":"), { "a", "b", "c" })
        eq(Util.split("a:::b:::c", ":::"), { "a", "b", "c" })
    end)
    it("find", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        eq(Util.find_element(tbl, 2, cmp), 2)
        eq(Util.find_element(tbl, 5, cmp), 0)
    end)
    it("remove", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        Util.remove_element(tbl, 2, cmp)
        eq(tbl, { 1, 3, 4 })
        Util.remove_element(tbl, 2, cmp)
        eq(tbl, { 1, 3, 4 })
    end)
    it("disable input", function()
        Util.disable_buffer_modification()
        Util.simulate_input("abc")
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for _, line in ipairs(buf_lines) do
            eq(line, "")
        end
    end)
end)
