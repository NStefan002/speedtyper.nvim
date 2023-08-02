local M = {}
local util = require("speedtyper.util")
local api = vim.api

local defaults = {
    time = 30,
    window = {
        height = 0.15,      -- integer grater than 0 or float in range (0, 1)
        width = 0.55,
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    }
}

---@param size integer | float
---@param viewport integer
local function calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

function M.open_float(opts)
    local lines = vim.o.lines - vim.o.cmdheight
    local columns = vim.o.columns
    local height = calc_size(opts.height, lines)
    local width = calc_size(opts.width, columns)
    local bufnr = api.nvim_create_buf(false, true)
    local winnr = api.nvim_open_win(bufnr, true, {
        relative = "editor",
        row = math.floor((lines - height) / 2),
        col = math.floor((columns - width) / 2),
        anchor = "NW",
        width = width,
        height = height,
        border = opts.border,
        title = "Speedtyper",
        title_pos = "center",
        noautocmd = true,
    })
    return winnr
end

function M.start()

end

function M.setup(opts)
    opts = opts or defaults
    api.nvim_create_user_command("Speedtyper", function(event)
        local time = event.args or opts.time
        print(time)
        M.open_float(opts.window)
    end, {
        nargs = 1,
        desc = "Start Speedtyper with <arg> time on the clock.",
    })
end

return M
