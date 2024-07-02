local eq = assert.are.same

describe("Char info tests", function()
    local char_info = require("speedtyper.char_info")

    it("equals", function()
        local c1 = char_info.new("a", "a", 1, 1)
        local c2 = char_info.new("a", "a", 1, 1)

        eq(true, c1 == c2)

        c1 = char_info.new("a", "b", 1, 1)

        eq(false, char_info.equal(c1, c2))
    end)
end)
