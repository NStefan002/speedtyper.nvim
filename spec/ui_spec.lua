---@diagnostic disable: invisible

local api = vim.api
local eq = assert.are.same

describe("UI tests", function()
    local ui = require("speedtyper.ui")

    before_each(function()
        ui:close() -- make sure ui is closed before each test
    end)

    it("toggle ui", function()
        ui:toggle()

        eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:toggle()

        eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:toggle()

        eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:toggle()

        eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))
    end)

    it("ui _open _close", function()
        ui:open()

        eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:close()

        eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:open()

        eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

        ui:close()

        eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))
    end)

    it("user exiting via :q", function()
        ui:open()

        vim.cmd("q")

        eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))
        eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))

        ui:open()

        eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
        eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))
    end)

    it("leaving the buffer with something like :bprev / :bnext / :e file", function()
        ui:open()

        vim.cmd.edit("some_random_file")

        -- has to be scheduled because in the autocmd we are scheduling the close
        vim.schedule(function()
            eq(false, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
            eq(false, api.nvim_win_is_valid(vim.g.speedtyper_winnr))

            ui:open()

            eq(true, api.nvim_buf_is_valid(vim.g.speedtyper_bufnr))
            eq(true, api.nvim_win_is_valid(vim.g.speedtyper_winnr))
        end)
    end)

    it("restore vim.opt", function()
        local gui_cursor = api.nvim_get_option_value("guicursor", { scope = "global" })

        ui:open()
        ui:close()

        eq(gui_cursor, api.nvim_get_option_value("guicursor", { scope = "global" }))
    end)
end)
