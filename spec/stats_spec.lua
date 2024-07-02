local eq = assert.are.same

describe("Typo tracker tests", function()
    local stats = require("speedtyper.stats")
    local char_info = require("speedtyper.char_info")

    before_each(function()
        stats:reset()
    end)

    it("check current character", function()
        stats:check_curr_char("a", "a", 1, 1)
        local c = char_info.new("a", "a", 1, 1)
        local sc = stats.text_info:get_table()[1]
        eq(true, c == sc)
    end)
end)
