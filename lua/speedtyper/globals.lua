local M = {}
local api = vim.api

M.ns_id = api.nvim_create_namespace("SpeedTyper")

M.bufnr = -1

M.winnr = -1

return M
