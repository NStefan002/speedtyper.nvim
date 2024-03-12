---@diagnostic disable: undefined-field, undefined-global
local Logger = require("speedtyper.logger")

local eq = assert.are.same

describe("Logger tests", function()
    before_each(function()
        require("speedtyper")
        Logger:clear()
        vim.g.speedtyper_settings = vim.tbl_deep_extend(
            "force",
            vim.g.speedtyper_settings,
            { debug_mode = { ["on"] = true, ["off"] = false } }
        )
    end)

    it("new lines are removed, every log call is one line", function()
        Logger:log("hello\nworld")
        eq({ "hello world" }, Logger.lines)
    end)

    it("new lines with vim.inspect get removed too", function()
        Logger:log({ hello = "world", world = "hello" })
        eq({ '{ hello = "world", world = "hello" }' }, Logger.lines)
    end)

    it("max lines", function()
        Logger.max_lines = 1
        Logger:log("one")
        eq({ "one" }, Logger.lines)
        Logger:log("two")
        eq({ "two" }, Logger.lines)
    end)
end)
