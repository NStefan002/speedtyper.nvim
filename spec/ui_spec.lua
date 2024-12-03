local api = vim.api
local eq = assert.are.same

describe("UI tests", function()
    local plugin_path = vim.uv.fs_realpath("./")
    vim.cmd(("set rtp+=%s"):format(plugin_path))

    local ui = require("speedtyper.ui")
    local globals = require("speedtyper.globals")

    before_each(function()
        ui:_close() -- make sure ui is closed before each test
    end)

    it("toggle ui", function()
        ui:toggle()

        eq(true, api.nvim_buf_is_valid(globals.bufnr))
        eq(true, api.nvim_win_is_valid(globals.winnr))

        ui:toggle()

        eq(false, api.nvim_buf_is_valid(globals.bufnr))
        eq(false, api.nvim_win_is_valid(globals.winnr))
        eq(-1, globals.bufnr)
        eq(-1, globals.winnr)

        ui:toggle()

        eq(true, api.nvim_buf_is_valid(globals.bufnr))
        eq(true, api.nvim_win_is_valid(globals.winnr))

        ui:toggle()

        eq(false, api.nvim_buf_is_valid(globals.bufnr))
        eq(false, api.nvim_win_is_valid(globals.winnr))
        eq(-1, globals.bufnr)
        eq(-1, globals.winnr)
    end)

    it("ui _open _close", function()
        ui:_open()

        eq(true, api.nvim_buf_is_valid(globals.bufnr))
        eq(true, api.nvim_win_is_valid(globals.winnr))

        ui:_close()

        eq(false, api.nvim_buf_is_valid(globals.bufnr))
        eq(false, api.nvim_win_is_valid(globals.winnr))
        eq(-1, globals.bufnr)
        eq(-1, globals.winnr)

        ui:_open()

        eq(true, api.nvim_buf_is_valid(globals.bufnr))
        eq(true, api.nvim_win_is_valid(globals.winnr))

        ui:_close()

        eq(false, api.nvim_buf_is_valid(globals.bufnr))
        eq(false, api.nvim_win_is_valid(globals.winnr))
        eq(-1, globals.bufnr)
        eq(-1, globals.winnr)
    end)

    it("user exiting via :q", function()
        ui:_open()

        vim.cmd("q")

        -- NOTE: we have to schedule this because of the
        -- WinClosed autocmd in ui.lua
        vim.schedule(function()
            eq(false, api.nvim_buf_is_valid(globals.bufnr))
            eq(false, api.nvim_win_is_valid(globals.winnr))
            eq(-1, globals.bufnr)
            eq(-1, globals.winnr)

            ui:_open()

            eq(true, api.nvim_buf_is_valid(globals.bufnr))
            eq(true, api.nvim_win_is_valid(globals.winnr))
        end)
    end)

    it("leaving the buffer with something like :bprev / :bnext / :e file", function()
        ui:_open()

        vim.cmd.edit("some_random_file")

        -- NOTE: we have to schedule this because of the
        -- BufDelete/BufWinLeave autocmd in ui.lua
        vim.schedule(function()
            eq(false, api.nvim_buf_is_valid(globals.bufnr))
            eq(false, api.nvim_win_is_valid(globals.winnr))
            eq(-1, globals.bufnr)
            eq(-1, globals.winnr)

            ui:_open()

            eq(true, api.nvim_buf_is_valid(globals.bufnr))
            eq(true, api.nvim_win_is_valid(globals.winnr))
        end)
    end)

    it("restore vim.opt", function()
        local gui_cursor = api.nvim_get_option_value("guicursor", { scope = "global" })

        ui:_open()
        ui:_close()

        eq(gui_cursor, api.nvim_get_option_value("guicursor", { scope = "global" }))
    end)
end)
