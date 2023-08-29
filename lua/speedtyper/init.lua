local M = {}
local api = vim.api
local menu = require("speedtyper.menu")

math.randomseed(os.time())

---@param opts table<string, any>
function M.setup(opts)
    require("speedtyper.config").override_opts(opts)
    local ns_id = api.nvim_create_namespace("Speedtyper")
    local util = require("speedtyper.util")
    api.nvim_create_user_command("Speedtyper", function(event)
        if #event.fargs > 0 then
            util.error("Too many arguments!")
            return
        end
        menu.show()
    end, {
        nargs = "*",
        desc = "Start Speedtyper with <arg> (or default if not provided) time on the clock.",
    })
end

return M
