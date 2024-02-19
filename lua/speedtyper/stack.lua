---@class SpeedTyperStack
---@field _stack table
---@field _top integer

local Stack = {}
Stack.__index = Stack

function Stack.new()
    local self = {
        _stack = {},
        _top = 0,
    }
    return setmetatable(self, Stack)
end

function Stack:is_empty()
    return self._top == 0
end

function Stack:size()
    return self._top
end

function Stack:push(value)
    self._top = self._top + 1
    self._stack[self._top] = value
end

function Stack:pop()
    if self:is_empty() then
        return nil
    end
    local value = self._stack[self._top]
    self._stack[self._top] = nil
    self._top = self._top - 1
    return value
end

function Stack:get_table()
    return self._stack
end

function Stack:clear()
    self._stack = {}
    self._top = 0
end

return Stack
