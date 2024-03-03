---@diagnostic disable: undefined-field, undefined-global
require("speedtyper")
local Text = require("speedtyper.text")
local text = Text.new()
local eq = assert.are.same

describe("Text tests", function()
    before_each(function()
        require("plenary.reload").reload_module("speedtyper")
        text = Text.new()
    end)

    it("get word", function()
        local empty_word = false
        for _ = 1, 10000 do
            if text:get_word() == "" then
                empty_word = true
                break
            end
        end
        eq(false, empty_word)
    end)

    it("win width high", function()
        local width_overflow = false
        for _ = 1, 10000 do
            local sentence = text:generate_sentence(80)
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
            local sentence = text:generate_sentence(20)
            if #sentence > 16 then
                width_overflow = true
                break
            end
        end
        eq(false, width_overflow)
    end)
end)
