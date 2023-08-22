local M = {}
local api = vim.api
local helper = require("speedtyper.helper")

---@param opts table
---@return integer, integer
function M.open_float(opts)
    local lines = vim.o.lines - vim.o.cmdheight
    local columns = vim.o.columns
    local height = helper.calc_size(opts.height, lines)
    local width = helper.calc_size(opts.width, columns)
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
    -- creating space for extmarks
    for _ = 1, 3 do
        vim.cmd.normal("o")
    end
    vim.cmd.normal("gg")
    vim.cmd.startinsert()
    return winnr, bufnr
end

return M
