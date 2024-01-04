---@diagnostic disable: undefined-field, undefined-global
local Text = require("speedtyper.text")
local eq = assert.are.same

describe("Text tests", function()
    before_each(function()
        Text = require("speedtyper.text")
        Text:set_lang("en")
    end)

    it("get word", function()
        local empty_word = false
        for _ = 1, 10000 do
            if Text:get_word() == "" then
                empty_word = true
                break
            end
        end
        eq(false, empty_word)
    end)

    it("win width high", function()
        local width_overflow = false
        for _ = 1, 10000 do
            local sentence = Text:generate_sentence(80)
            if #sentence > 76 then
                width_overflow = true
                break
            end
        end
        eq(false, width_overflow)
    end)

    it("win width low", function()
        local width_overflow = false
        for _ = 1, 10000 do
            local sentence = Text:generate_sentence(20)
            if #sentence > 16 then
                width_overflow = true
                break
            end
        end
        eq(false, width_overflow)
    end)
end)
