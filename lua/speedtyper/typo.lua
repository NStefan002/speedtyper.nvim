local Util = require("speedtyper.util")

---@class SpeedTyperTyposTracker
---@field ns_id integer
---@field highlight string
---@field bufnr integer
---@field typos Position[]

---@alias Position { line: integer, col: integer }

local SpeedTyperTyposTracker = {}

---@param bufnr integer
---@param highlight string
function SpeedTyperTyposTracker:new(bufnr, highlight)
    local typo = setmetatable({
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        typos = {},
        bufnr = bufnr,
        highlight = highlight,
    }, self)
    self.__index = self
    return typo
end

---@param should_be string
function SpeedTyperTyposTracker:check_curr_char(should_be)
    if #should_be > 1 then
        return
    end
    local line, col = Util.get_cursor_pos()
    local typed = vim.api.nvim_buf_get_text(self.bufnr, line - 1, col - 1, line - 1, col, {})[1]
    if typed ~= should_be then
        self.typos = self.typos or {}
        table.insert(self.typos, { line, col })
    else
        Util.remove_element(self.typos, { line, col }, function(a, b)
            return a[1] == b[1] and a[2] == b[2]
        end)
    end
end

function SpeedTyperTyposTracker:mark_typo(line, col)
    vim.api.nvim_buf_add_highlight(self.bufnr, self.ns_id, self.highlight, line - 1, col - 1, col)
end

return SpeedTyperTyposTracker
