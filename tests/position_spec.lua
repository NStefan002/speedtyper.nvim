---@diagnostic disable: undefined-field, undefined-global
local Position = require("speedtyper.position")
local eq = assert.are.same

describe("Position tests", function()
    before_each(function()
        Position = require("speedtyper.position")
    end)

    it("update", function()
        local pos = Position.new(1, 1)

        eq(pos.line, 1)
        eq(pos.col, 1)

        pos:update(2, 3)

        eq(pos.line, 2)
        eq(pos.col, 3)
    end)

    it("equals", function()
        local pos1 = Position.new(1, 1)
        local pos2 = Position.new(1, 1)

        eq(true, pos1 == pos2)

        pos1:update(2, 3)

        eq(false, pos1 == pos2)
        pos2:update(2, 3)

        eq(true, Position.equal(pos1, pos2))
    end)
end)
