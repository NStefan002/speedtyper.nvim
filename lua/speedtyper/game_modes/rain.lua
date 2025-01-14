local api = vim.api
local globals = require("speedtyper.globals")

---@class speedtyper.game_mode.rain
---@field timer uv_timer_t
---@field extm_ids integer[]
---@field text string[]
---@field text_generator speedtyper.text_generator
local Rain = {}
Rain.__index = Rain

---@return speedtyper.game_mode.rain
function Rain.new()
    local self = setmetatable({
        timer = nil,
        extm_ids = {},
        text = {
            "Rain mode coming soon!",
            "Please select another game mode.",
        },
        text_generator = nil,
    }, Rain)
    return self
end

function Rain:start()
    for i, line in ipairs(self.text) do
        api.nvim_buf_set_extmark(globals.bufnr, globals.ns_id, i + 1, 0, {
            virt_text = { { line, "speedtyper.hl.sub" } },
            virt_text_win_col = 0,
            priority = globals.extmark_priority,
        })
    end
end

function Rain:stop()
    self.text = {}
end

return Rain.new()
