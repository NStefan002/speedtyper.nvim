local eq = assert.are.same

describe("Util test", function()
    local util = require("speedtyper.util")

    it("simulate input", function()
        util.simulate_input("abc")
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        eq("abc", buf_lines[1])

        util.simulate_input("<CR>b")
        buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        eq("abc", buf_lines[1])
        eq("b", buf_lines[2])
    end)

    it("compare floats", function()
        eq(true, util.equals(1.535453, 1.535453))
        eq(false, util.equals(1.535453, 1.535452))
        eq(false, util.equals(1 / 2, 2 / 4 + 0.000000000001))
        eq(true, util.equals(1 / 3, 33 / 99))
        eq(true, util.equals(1.0000000000, 1.00000000000))
    end)

    it("clear text", function()
        util.clear_buffer_text(5)
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, line in ipairs(buf_lines) do
            if i <= 5 then
                eq("", line)
            end
        end
    end)

    it("trim", function()
        eq("a", util.trim("  a"))
        eq("a", util.trim("a  "))
        eq("a", util.trim("   a  "))
        eq("a .", util.trim("  a ."))
    end)

    it("split", function()
        eq({ "a", "b", "c" }, util.split("a b c"))
        eq({ "a", "b", "c" }, util.split("a:b:c", ":"))
        eq({ "a", "b", "c" }, util.split("a:::b:::c", ":::"))
    end)

    it("find", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        eq(2, util.find_element(tbl, 2, cmp))
        eq(0, util.find_element(tbl, 5, cmp))
    end)

    it("contains", function()
        local tbl = { 1, 2, 2, 4 }
        local function cmp(a, b)
            return a == b
        end
        eq(true, util.tbl_contains(tbl, 2, cmp))
        eq(false, util.tbl_contains(tbl, 5, cmp))
    end)

    it("remove", function()
        local tbl = { 1, 2, 3, 4 }
        local function cmp(a, b)
            return a == b
        end
        util.remove_element(tbl, 2, cmp)
        eq({ 1, 3, 4 }, tbl)
        util.remove_element(tbl, 2, cmp)
        eq({ 1, 3, 4 }, tbl)
    end)

    it("get word from sentence", function()
        local sentence = "this is some sentence"
        local word, idx = util.get_word_from_sentence(sentence, 1)
        eq("this", word)
        eq(1, idx)
        word, idx = util.get_word_from_sentence(sentence, 3)
        eq("this", word)
        eq(3, idx)
        word, idx = util.get_word_from_sentence(sentence, 4)
        eq("this", word)
        eq(4, idx)
        word, idx = util.get_word_from_sentence(sentence, 5)
        eq(" ", word)
        eq(1, idx)
        word, idx = util.get_word_from_sentence(sentence, 7)
        eq("is", word)
        eq(2, idx)
        word, idx = util.get_word_from_sentence(sentence, #sentence)
        eq("sentence", word)
        eq(8, idx)
    end)

    it("create cursor", function()
        local cursor = util.create_cursor("line", false)
        eq("i:ver30", cursor)

        cursor = util.create_cursor("block", true)
        eq("i:block,i:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor", cursor)
    end)
end)
