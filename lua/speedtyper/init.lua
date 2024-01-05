local M = {}
local api = vim.api

math.randomseed(os.time())

---@param opts table<string, any>
function M.setup(opts)
    require("speedtyper.config").override_opts(opts)
    api.nvim_create_namespace("Speedtyper")
    local util = require("speedtyper.util")
    api.nvim_create_user_command("Speedtyper", function(event)
        if #event.fargs > 0 then
            util.error("Too many arguments!")
            return
        end
        require("speedtyper.menu").show()
    end, {
        nargs = 0,
        desc = "Start Speedtyper.",
    })
end

return M
