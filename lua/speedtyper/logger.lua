local Util = require("speedtyper.util")

---@class SpeedTyperLogger
---@field lines string[]
---@field max_lines integer
local Logger = {}
Logger.__index = Logger

function Logger.new()
    local self = setmetatable({
        lines = {},
        max_lines = 50,
    }, Logger)
    return self
end

---@param ... any
function Logger:log(...)
    local enabled = vim.g.speedtyper_settings.debug_mode["on"]
    if not enabled then
        return
    end
    local processed = {}
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if type(item) == "table" then
            item = vim.inspect(item)
        end
        table.insert(processed, item)
    end

    local lines = {}
    for _, line in ipairs(processed) do
        local split = Util.split(line, "\n")
        for _, l in ipairs(split) do
            l = Util.trim(l)
            table.insert(lines, l)
        end
    end

    table.insert(self.lines, table.concat(lines, " "))

    while #self.lines > self.max_lines do
        table.remove(self.lines, 1)
    end
end

function Logger:clear()
    self.lines = {}
end

function Logger:display()
    local enabled = vim.g.speedtyper_settings.debug_mode["on"]
    if not enabled then
        return
    end
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, self.lines)
    vim.api.nvim_win_set_buf(0, bufnr)
end

return Logger.new()
