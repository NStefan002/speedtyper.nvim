local util = require("speedtyper.util")

local M = {}

function M.setup()
    util.hl("speedtyper.hl.bg", { link = "Folded" })
    util.hl("speedtyper.hl.cursor", { link = "IncSearch" })
    util.hl("speedtyper.hl.error", { link = "DiagnosticUnderlineError" })
    util.hl("speedtyper.hl.main", { link = "DiagnosticHint" })
    util.hl("speedtyper.hl.sub", { link = "Comment" })
    util.hl("speedtyper.hl.text", { link = "Normal" })
end

return M
