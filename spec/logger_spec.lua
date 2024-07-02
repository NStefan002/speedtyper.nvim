local eq = assert.are.same

describe("Logger tests", function()
    local logger = require("speedtyper.logger")
    local settings = require("speedtyper.settings")
    settings.general.debug_mode = true

    before_each(function()
        logger:clear()
    end)

    it("new lines are removed, every log call is one line", function()
        logger:log("hello\nworld")
        eq({ "hello world" }, logger.lines)
    end)

    it("new lines with vim.inspect get removed too", function()
        logger:log({ hello = "world", world = "hello" })
        eq({ '{ hello = "world", world = "hello" }' }, logger.lines)
    end)

    it("max lines", function()
        logger.max_lines = 1
        logger:log("one")
        eq({ "one" }, logger.lines)
        logger:log("two")
        eq({ "two" }, logger.lines)
    end)
end)
