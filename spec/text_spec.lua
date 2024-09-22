local eq = assert.are.same

describe("Text tests", function()
    local text = require("speedtyper.text")
    local util = require("speedtyper.util")

    before_each(function()
        text:update_lang()
    end)

    it("capitalize word", function()
        eq(text._capitalize_word("word"), "Word")
        eq(text._capitalize_word("Word"), "Word")
    end)

    it("high width generate sentence", function()
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

    it("low width generate sentence", function()
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

    it("generate n words", function()
        local n = 60
        local width = 80
        local mistake = false
        for _ = 1, 10000 do
            local paragraph = text:generate_n_words_text(width, n)
            local total_words = 0
            for _, line in ipairs(paragraph) do
                if #line > width - 4 then
                    mistake = true
                    break
                end
                total_words = total_words + #util.split(line, " ")
            end
            if total_words ~= n then
                mistake = true
                break
            end
        end
        eq(false, mistake)
    end)

    it("generate n lines", function()
        local n = 3
        local width = 80
        local mistake = false
        for _ = 1, 10000 do
            local paragraph = text:generate_n_lines_text(n, width)
            local total_words = 0
            for _, line in ipairs(paragraph) do
                if #line > width - 4 then
                    mistake = true
                    break
                end
                total_words = total_words + #util.split(line, " ")
            end
            if total_words < n then
                mistake = true
                break
            end
        end
        eq(false, mistake)
    end)
end)
