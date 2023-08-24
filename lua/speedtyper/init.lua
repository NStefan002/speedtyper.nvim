local M = {}
local api = vim.api

math.randomseed(os.time())

M.default_opts = {
    time = 30,
    window = {
        height = 0.15,      -- integer grater than 0 or float in range (0, 1)
        width = 0.55,       -- integer grater than 0 or float in range (0, 1)
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    },
    language = "en",        -- currently only only supports English
}

---@param opts table<string, any>
function M.setup(opts)
    opts = opts or {}
    opts = vim.tbl_deep_extend("force", M.default_opts, opts)
    require("speedtyper.langs").set_lang(opts.language)
    local ns_id = api.nvim_create_namespace("Speedtyper")
    local runner = require("speedtyper.runner")
    local window = require("speedtyper.window")
    local timer = require("speedtyper.timer")
    local util = require("speedtyper.util")
    -- one or zero arguments
    api.nvim_create_user_command("Speedtyper", function(event)
        if #event.fargs > 1 then
            util.error("Too many arguments!")
            return
        end
        local time = tonumber(event.fargs[1]) or opts.time
        local winnr, bufnr = window.open_float(opts.window)
        runner.start(bufnr)
        timer.create_timer(time, bufnr)
        if package.loaded["cmp"] then
            -- disable cmp if loaded, we don't want the completion while practising typing :)
            require("cmp").setup.buffer({ enabled = false })
        end
        vim.bo[bufnr].filetype = "speedtyper"
        vim.opt_local.nu = false
        vim.opt_local.rnu = false
        vim.opt_local.fillchars = { eob = " " }
    end, {
        nargs = "*",
        desc = "Start Speedtyper with <arg> (or default if not provided) time on the clock.",
    })
end

return M
