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
        eq("abc", buf_lines[1])

        Util.simulate_input("<CR>b")
        buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        eq("abc", buf_lines[1])
        eq("b", buf_lines[2])
    end)
    it("compare floats", function()
        eq(true, Util.equals(1.535453, 1.535453))
        eq(false, Util.equals(1.535453, 1.535452))
        eq(false, Util.equals(1 / 2, 2 / 4 + 0.000000000001))
        eq(true, Util.equals(1 / 3, 33 / 99))
        eq(true, Util.equals(1.0000000000, 1.00000000000))
    end)
    it("clear text", function()
        Util.clear_buffer_text(5)
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, line in ipairs(buf_lines) do
            if i <= 5 then
                eq("", line)
            end
        end
    end)
    it("trim", function()
        eq("a", Util.trim("  a"))
        eq("a", Util.trim("a  "))
        eq("a", Util.trim("   a  "))
        eq("a .", Util.trim("  a ."))
    end)
    it("split", function()
        eq({ "a", "b", "c" }, Util.split("a b c"))
        eq({ "a", "b", "c" }, Util.split("a:b:c", ":"))
        eq({ "a", "b", "c" }, Util.split("a:::b:::c", ":::"))
    end)
    it("find", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        eq(2, Util.find_element(tbl, 2, cmp))
        eq(0, Util.find_element(tbl, 5, cmp))
    end)
    it("remove", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        Util.remove_element(tbl, 2, cmp)
        eq({ 1, 3, 4 }, tbl)
        Util.remove_element(tbl, 2, cmp)
        eq({ 1, 3, 4 }, tbl)
    end)
    it("disable input", function()
        Util.disable_buffer_modification()
        Util.simulate_input("abc")
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for _, line in ipairs(buf_lines) do
            eq("", line)
        end
    end)
    it("get word from sentence", function()
        local sentence = "this is some sentence"
        local word = Util.get_word_from_sentence(sentence, 1)
        eq("this", word)
        word = Util.get_word_from_sentence(sentence, 3)
        eq("this", word)
        word = Util.get_word_from_sentence(sentence, 4)
        eq("this", word)
        word = Util.get_word_from_sentence(sentence, 5)
        eq(" ", word)
        word = Util.get_word_from_sentence(sentence, 7)
        eq("is", word)
        word = Util.get_word_from_sentence(sentence, #sentence)
        eq("sentence", word)
    end)
end)
