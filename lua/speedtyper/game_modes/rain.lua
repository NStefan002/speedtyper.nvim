---@class SpeedTyperRain
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
        _prev_cursor_pos = nil,
    }
    return setmetatable(self, Rain)
end

function Rain:start()
    vim.api.nvim_buf_set_lines(self.bufnr, 2, 4, false, {
        "Rain mode coming soon!",
        "Please select another game mode.",
    })
end

function Rain:stop()
    self.bufnr = nil
end

return Rain
