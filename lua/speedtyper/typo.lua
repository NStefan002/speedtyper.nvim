local Util = require("speedtyper.util")
local Position = require("speedtyper.position")

---@class SpeedTyperTyposTracker
---@field ns_id integer
---@field highlight string
---@field bufnr integer
---@field typos Position[]

local SpeedTyperTyposTracker = {}
SpeedTyperTyposTracker.__index = SpeedTyperTyposTracker

---@param highlight string
---@param bufnr? integer
function SpeedTyperTyposTracker.new(highlight, bufnr)
    local typo = {
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        typos = {},
        bufnr = bufnr or 0,
        highlight = highlight,
    }
    return setmetatable(typo, SpeedTyperTyposTracker)
end

---@param should_be string
function SpeedTyperTyposTracker:check_curr_char(should_be)
    if #should_be > 1 then
        return
    end
    local line, col = Util.get_cursor_pos()
    if col == 1 then
        return
    end
    col = col - 1
    local typed = vim.api.nvim_buf_get_text(self.bufnr, line - 1, col - 1, line - 1, col, {})[1]
    if typed ~= should_be then
        self.typos = self.typos or {}
        table.insert(self.typos, Position.new(line, col))
        SpeedTyperTyposTracker._mark_typo(self, line, col)
    else
        Util.remove_element(self.typos, Position.new(line, col), function(a, b)
            return a == b
        end)
    end
end

function SpeedTyperTyposTracker:_mark_typo(line, col)
    vim.api.nvim_buf_add_highlight(self.bufnr, self.ns_id, self.highlight, line - 1, col - 1, col)
end

return SpeedTyperTyposTracker
