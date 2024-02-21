---@class SpeedTyperRain
---@field timer uv_timer_t
---@field bufnr integer
---@field ns_id integer
---@field extm_ids integer[]
---@field text string[]
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field prev_cursor_pos Position
local Rain = {}
Rain.__index = Rain

---@param bufnr integer
function Rain.new(bufnr)
    local self = {
        timer = nil,
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        extm_ids = {},
        text = {},
        text_generator = nil,
        typos_tracker = nil,
        prev_cursor_pos = nil,
    }
    return setmetatable(self, Rain)
end

function Rain:start()
    local lines = {
        "Rain mode coming soon!",
        "Please select another game mode.",
    }

    for i, line in ipairs(lines) do
        vim.api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i + 1, 0, {
            virt_text = { { line, "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
    end
end

function Rain:stop()
    self.bufnr = nil
end

return Rain
