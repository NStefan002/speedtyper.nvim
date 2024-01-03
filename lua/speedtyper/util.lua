local M = {}
local api = vim.api

---notify user of an error
---@param msg string
function M.error(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.WARN, { title = "Speedtyper" })
end

---@param msg string
function M.info(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.INFO, { title = "Speedtyper" })
end

---@return integer
---@return integer
function M.get_cursor_pos()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return line, col
end

---@param a number
---@param b number
---@return boolean
function M.equal(a, b)
    return tostring(a) == tostring(b)
end

---@param extm_ids integer[]
function M.clear_extmarks(extm_ids)
    for _, id in pairs(extm_ids) do
        api.nvim_buf_del_extmark(0, api.nvim_get_namespaces()["Speedtyper"], id)
    end
end

---@param n integer number of lines to clear
function M.clear_text(n)
    local repl = {}
    for _ = 1, n do
        table.insert(repl, "")
    end
    api.nvim_buf_set_lines(0, 0, n, false, repl)
end

---@param file_path string
function M.read_file(file_path)
    local reader = io.open(file_path, "r")
    if reader == nil then
        M.error("Failed to read from the file: " .. file_path)
        return
    end

    local words = {}
    for line in reader:lines("*l") do
        for word in string.gmatch(line, "%S+") do
            table.insert(words, word)
        end
    end

    io.close(reader)
    return words
end

function M.disable_modifying_buffer()
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    local keys_to_disable = {
        "i",
        "a",
        "o",
        "r",
        "x",
        "s",
        "d",
        "c",
        "u",
        "p",
        "I",
        "A",
        "O",
        "R",
        "S",
        "D",
        "C",
        "U",
        "P",
        ".",
    }
    for _, key in pairs(keys_to_disable) do
        vim.keymap.set({ "n", "v" }, key, "<Nop>", { buffer = 0 })
    end
end

return M
