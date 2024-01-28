---@class SpeedTyperStats
---@field bufnr integer
---@field ns_id integer

local SpeedTyperStats = {}
SpeedTyperStats.__index = SpeedTyperStats

---@param bufnr integer
function SpeedTyperStats.new(bufnr)
    local stats = {
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
    }
    return setmetatable(stats, SpeedTyperStats)
end

-- TODO: implement these functions
-- function SpeedTyperStats:display_stats() end
-- function SpeedTyperStats:_calculate_wpm() end
-- function SpeedTyperStats:_calculate_raw_wpm() end
-- function SpeedTyperStats:_calculate_acc() end

return SpeedTyperStats
