local Speedtyper = {}

--- Your plugin configuration with its default values.
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Speedtyper.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
}

--- Define your speedtyper setup.
---
---@param options table Module config table. See |Speedtyper.options|.
---
---@usage `require("speedtyper").setup()` (add `{}` with your |Speedtyper.options| table)
function Speedtyper.setup(options)
    options = options or {}

    Speedtyper.options = vim.tbl_deep_extend("keep", options, Speedtyper.options)

    return Speedtyper.options
end

return Speedtyper
