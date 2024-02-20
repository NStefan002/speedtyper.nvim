---@diagnostic disable: undefined-field, undefined-global
local st = require("speedtyper")
local speedtyper = st.setup()
local eq = assert.are.same
local Util = require("speedtyper.util")

describe("UI tests", function()
    before_each(function()
        require("plenary.reload").reload_module("speedtyper")
        st = require("speedtyper")
        speedtyper = st.setup()
    end)

    it("Toggle ui", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))

        speedtyper.ui:toggle()

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))

        speedtyper.ui:toggle()

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)
    end)

    it("ui _open _close", function()
        speedtyper.ui:_open()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))

        speedtyper.ui:_close()

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)

        speedtyper.ui:_open()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))

        speedtyper.ui:_close()

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)
    end)

    it("user exiting via :q", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        vim.cmd("q")

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))
    end)

    it("user leaving the window with something like :bprev / :bnext", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        vim.cmd("bprev")

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))
    end)

    it("user leaving the window with something like <C-w><C-w>", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        Util.simulate_keypress("<C-w><C-w>")

        eq(false, vim.api.nvim_buf_is_valid(bufnr))
        eq(false, vim.api.nvim_win_is_valid(winnr))
        eq(nil, speedtyper.ui.bufnr)
        eq(nil, speedtyper.ui.winnr)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(true, vim.api.nvim_buf_is_valid(bufnr))
        eq(true, vim.api.nvim_win_is_valid(winnr))
    end)
end)
