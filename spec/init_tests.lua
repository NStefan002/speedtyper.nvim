local plugin_path = vim.uv.fs_realpath("./")
vim.cmd(("set rtp+=%s"):format(plugin_path))
vim.cmd("runtime! plugin/**/*.{vim,lua}")
-- initialize the plugin by calling the command
vim.cmd("SpeedTyper")
