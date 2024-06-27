local api = vim.api
local globals = require("speedtyper.globals")

---@class SpeedTyperRain
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field text string[]
---@field text_generator SpeedTyperText
---@field typos_tracker SpeedTyperTyposTracker
---@field prev_cursor_pos Position
local Rain = {}
Rain.__index = Rain

function Rain.new()
    local self = {
        timer = nil,
        extm_ids = {},
        text = {
            "Rain mode coming soon!",
            "Please select another game mode.",
        },
        text_generator = nil,
        typos_tracker = nil,
        prev_cursor_pos = nil,
    }
    return setmetatable(self, Rain)
end

function Rain:start()
    for i, line in ipairs(self.text) do
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, i + 1, 0, {
            virt_text = { { line, "SpeedTyperTextUntyped" } },
            virt_text_win_col = 0,
        })
    end
end

function Rain:stop()
    self.text = {}
end

return Rain
