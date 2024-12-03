local api = vim.api

local M = {}

---@type integer
M.ns_id = api.nvim_create_namespace("SpeedTyper")

---@type integer
M.bufnr = -1

---@type integer
M.winnr = -1

-- constants used for positioning and sizing of elements,
-- 0-indexed, because most of the buf/win api's use 0-indexing

---@type integer
M.win_height = 10

---@type integer
M.menu_first_line = 0

---@type integer
M.text_first_line = M.menu_first_line + 3

---@type integer
M.text_num_lines = 3

---@type integer
M.text_middle_line = math.floor((M.text_first_line + M.text_num_lines) / 2) + 1

---@type integer
M.stats_line = M.text_first_line + M.text_num_lines + 2

---@type integer
M.info_line = M.text_first_line - 1

-- for calculating different things

---@type integer
M.min_to_sec = 60

---@type integer
M.sec_to_ms = 1000

---@type integer
M.word_length = 5

return M
