local M = {}
local api = vim.api

---calculate the dimension of the floating window
---@param size number
---@param viewport integer
local function calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@param opts table<string, any>
---@return integer
---@return integer
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
    return winnr, bufnr
end

return M
