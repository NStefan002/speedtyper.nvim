---@diagnostic disable: undefined-field, undefined-global
local st = require("speedtyper")
local speedtyper = st.setup()
local eq = assert.are.same

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

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)

        speedtyper.ui:toggle()

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)

        speedtyper.ui:toggle()

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)
    end)

    it("ui _open _close", function()
        speedtyper.ui:_open(require("speedtyper.config").get_default_config().window)

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)

        speedtyper.ui:_close()

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)

        speedtyper.ui:_open(require("speedtyper.config").get_default_config().window)

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)

        speedtyper.ui:_close()

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)
    end)

    it("user exiting via :q", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        vim.cmd("q")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)
    end)

    it("user leaving the window with something like :bprev / :bnext", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        vim.cmd("bprev")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)
    end)

    it("user leaving the window with something like <C-w><C-w>", function()
        speedtyper.ui:toggle()

        local bufnr = speedtyper.ui.bufnr
        local winnr = speedtyper.ui.winnr

        Util.simulate_keypress("<C-w><C-w>")

        eq(vim.api.nvim_buf_is_valid(bufnr), false)
        eq(vim.api.nvim_win_is_valid(winnr), false)
        eq(speedtyper.ui.bufnr, nil)
        eq(speedtyper.ui.winnr, nil)

        speedtyper.ui:toggle()

        bufnr = speedtyper.ui.bufnr
        winnr = speedtyper.ui.winnr

        eq(vim.api.nvim_buf_is_valid(bufnr), true)
        eq(vim.api.nvim_win_is_valid(winnr), true)
    end)
end)
