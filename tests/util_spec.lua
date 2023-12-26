local Util = require("speedtyper.util")
local eq = assert.are.same

describe("Util test", function()
    before_each(function()
        Util = require("speedtyper.util")
    end)
    it("compare floats", function()
        eq(Util.equals(1.535453, 1.535453), true)
        eq(Util.equals(1.535453, 1.535452), false)
        eq(Util.equals(1 / 2, 2 / 4 + 0.000000000001), false)
        eq(Util.equals(1 / 3, 33 / 99), true)
        eq(Util.equals(1.0000000000, 1.00000000000), true)
    end)
    it("clear text", function()
        eq(Util.clear_text(5), { "", "", "", "", "" })
        eq(Util.clear_text(0), {})
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
end)
