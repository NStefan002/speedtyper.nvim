local Util = require("speedtyper.util")
local Position = require("speedtyper.position")

---@class SpeedTyperTyposTracker
---@field ns_id integer
---@field bufnr integer
---@field typos Position[]

local SpeedTyperTyposTracker = {}
SpeedTyperTyposTracker.__index = SpeedTyperTyposTracker

---@param bufnr? integer
function SpeedTyperTyposTracker.new(bufnr)
    local typo = {
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        typos = {},
        num_typos = 0,
        bufnr = bufnr or 0,
    }
    return setmetatable(typo, SpeedTyperTyposTracker)
end

---@param should_be string
function SpeedTyperTyposTracker:check_curr_char(should_be)
    if #should_be ~= 1 then
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
        self.num_typos = self.num_typos + 1
        SpeedTyperTyposTracker._mark_typo(self, line, col)
    else
        local last_size = #self.typos
        Util.remove_element(self.typos, Position.new(line, col))
        if last_size ~= #self.typos then
            self.num_typos = self.num_typos - 1
        end
    end
end

function SpeedTyperTyposTracker:_mark_typo(line, col)
    vim.api.nvim_buf_add_highlight(
        self.bufnr,
        self.ns_id,
        "SpeedTyperTextError",
        line - 1,
        col - 1,
        col
    )
end

function SpeedTyperTyposTracker:redraw()
    for _, pos in ipairs(self.typos) do
        SpeedTyperTyposTracker._mark_typo(self, pos.line, pos.col)
    end
end

return SpeedTyperTyposTracker
