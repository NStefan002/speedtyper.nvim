local M = {}
local api = vim.api

math.randomseed(os.time())

---@param opts table<string, any>
function M.setup(opts)
    require("speedtyper.config").override_opts(opts)
    local ns_id = api.nvim_create_namespace("Speedtyper")
    local runner = require("speedtyper.runner")
    local window = require("speedtyper.window")
    local util = require("speedtyper.util")
    api.nvim_create_user_command("Speedtyper", function(event)
        if #event.fargs > 0 then
            util.error("Too many arguments!")
            return
        end
        local winnr, bufnr = window.open_float(opts.window)
        runner.start()
        if package.loaded["cmp"] then
            -- disable cmp if loaded, we don't want the completion while practising typing :)
            require("cmp").setup.buffer({ enabled = false })
        end
        vim.opt_local.nu = false
        vim.opt_local.rnu = false
        vim.opt_local.fillchars = { eob = " " }
    end, {
        nargs = "*",
        desc = "Start Speedtyper with <arg> (or default if not provided) time on the clock.",
    })
end

return M
