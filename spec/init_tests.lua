local plugin_path = vim.uv.fs_realpath("./")
vim.cmd(("set rtp+=%s"):format(plugin_path))
-- source all files in plugin/ directory
vim.cmd("runtime! plugin/**/*.{vim,lua}")
