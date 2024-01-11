---@class SpeedTyperStopwatch: SpeedTyperGameMode

local Stopwatch = {}
Stopwatch.__index = Stopwatch

---@param bufnr integer
function Stopwatch.new(bufnr)
    local rain = {
        timer = nil,
        bufnr = bufnr,
        ns_id = vim.api.nvim_create_namespace("SpeedTyper"),
        extm_ids = {},
        text = {},
        text_generator = nil,
        typos_tracker = nil,
        _prev_cursor_pos = nil,
    }
    return setmetatable(rain, Stopwatch)
end

function Stopwatch:start()
    vim.api.nvim_buf_set_lines(self.bufnr, 2, 4, false, {
        "Stopwatch mode coming soon!",
        "Please select another game mode.",
    })
end

function Stopwatch:stop()
    self.bufnr = nil
end

return Stopwatch
