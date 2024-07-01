---@class SpeedTyperStack
---@field private _stack table
---@field private _top integer
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

---@return any?
function Stack:peek()
    if self:is_empty() then
        return nil
    end
    return vim.deepcopy(self._stack[self._top])
end

function Stack:pop()
    if self:is_empty() then
        return
    end
    self._stack[self._top] = nil
    self._top = self._top - 1
end

function Stack:pop_n(n)
    for _ = 1, n do
        self:pop()
    end
end

function Stack:get_table()
    return self._stack
end

function Stack:clear()
    self._stack = {}
    self._top = 0
end

return Stack
