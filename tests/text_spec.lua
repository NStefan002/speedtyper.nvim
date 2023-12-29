local Text = require("speedtyper.text")
local eq = assert.are.same

describe("Text tests", function()
    before_each(function()
        Text = require("speedtyper.text")
        Text:set_lang("en")
    end)

    it("get word", function()
        eq(Text:get_word() ~= "", true)
    end)

    it("max len", function()
        eq(#(Text:generate_sentence(60)) <= 60, true)
    end)
end)
