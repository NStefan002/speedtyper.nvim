local api = vim.api
local util = require("speedtyper.util")
local position = require("speedtyper.position")
local globals = require("speedtyper.globals")

---@class SpeedTyperTyposTracker
---@field typos Position[]
local TyposTracker = {}
TyposTracker.__index = TyposTracker

function TyposTracker.new()
    local self = setmetatable({
        typos = {},
    }, TyposTracker)
    return self
end

---@param should_be string
---@return boolean
function TyposTracker:check_curr_char(should_be)
    local line, col = util.get_cursor_pos()
    if col == 0 then
        return true
    end
    local typed = api.nvim_buf_get_text(globals.bufnr, line, col - 1, line, col, {})[1]
    if typed ~= should_be then
        self.typos = self.typos or {}
        table.insert(self.typos, position.new(line, col))
        self:_mark_typo(line, col)
        return false
    end
    util.remove_element(self.typos, position.new(line, col))
    return true
end

function TyposTracker:redraw()
    for _, pos in ipairs(self.typos) do
        self:_mark_typo(pos.line, pos.col)
    end
end

function TyposTracker:reset()
    self.typos = {}
end

---@param line integer
---@param col integer
function TyposTracker:_mark_typo(line, col)
    api.nvim_buf_add_highlight(
        globals.bufnr,
        globals.ns_id,
        "SpeedTyperTextError",
        line,
        col - 1,
        col
    )
end

return TyposTracker.new()
