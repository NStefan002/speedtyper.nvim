local M = {}
local api = vim.api

---@type integer
M.ns_id = api.nvim_create_namespace("SpeedTyper")

---@type integer
M.bufnr = -1

---@type integer
M.winnr = -1

return M
