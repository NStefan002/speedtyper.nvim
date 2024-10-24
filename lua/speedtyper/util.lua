local api = vim.api
local globals = require("speedtyper.globals")

local M = {}

---notify user of an error
---@param msg string
function M.error(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.ERROR, { title = "Speedtyper" })
    require("speedtyper.logger"):log(msg)
end

---@param msg string
function M.info(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.INFO, { title = "Speedtyper" })
end

---returns the current position of the cursor, 0-indexed
---@return integer
---@return integer
function M.get_cursor_pos()
    local line = vim.fn.line(".") - 1
    local col = vim.fn.col(".") - 1
    return line, col
end

---@param line integer
---@param col integer
---@param winnr integer
function M.set_cursor_pos(line, col, winnr)
    vim.schedule(function()
        api.nvim_win_set_cursor(winnr, { line, col })
    end)
end

---HACK: compare two floats
---@param a number
---@param b number
---@return boolean
function M.equals(a, b)
    return tostring(a) == tostring(b)
end

---@param n integer number of empty lines
---@param bufnr? integer
function M.clear_buffer_text(n, bufnr)
    local repl = {}
    for _ = 1, n do
        table.insert(repl, "")
    end
    api.nvim_buf_set_lines(bufnr or 0, 0, n, false, repl)
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

---@param bufnr integer
function M.disable_buffer_modification(bufnr)
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param str string
function M.trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

---@param str string
---@param sep? string
function M.split(str, sep)
    sep = sep or "%s" -- whitespace by default
    local t = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, s)
    end
    return t
end

---given the index of one of the characters in the sentence,
---return the word that contains that character, and the
---index of that character in the word
---@param sentence string
---@param idx integer
---@return string word the word that contains the character at `idx`
---@return integer idx index in the sentence -> index in the word
function M.get_word_from_sentence(sentence, idx)
    if sentence:sub(idx, idx) == " " then
        return " ", 1
    end

    local word_begin = idx
    while word_begin > 0 and sentence:sub(word_begin, word_begin) ~= " " do
        word_begin = word_begin - 1
    end
    word_begin = word_begin + 1

    local word_end = idx
    while word_end <= #sentence and sentence:sub(word_end, word_end) ~= " " do
        word_end = word_end + 1
    end
    word_end = word_end - 1

    return sentence:sub(word_begin, word_end), idx - word_begin + 1
end

---@param tbl table
---@param el any
---@param cmp? fun(a: any, b: any): boolean returns true if elements are the same
---@return integer idx index of the element `el` or 0 if `tbl` does not contain `el`
function M.find_element(tbl, el, cmp)
    cmp = cmp or function(a, b)
        return a == b
    end
    for idx, val in ipairs(tbl) do
        if cmp(val, el) then
            return idx
        end
    end
    return 0
end

---@param tbl table
---@param el any
---@param cmp? fun(a: any, b: any): boolean returns true if elements are the same
---@return boolean
function M.tbl_contains(tbl, el, cmp)
    cmp = cmp or function(a, b)
        return a == b
    end
    return M.find_element(tbl, el, cmp) > 0
end

---@param tbl table
---@param el any
---@param cmp? fun(a: any, b: any): boolean returns true if elements are the same
function M.remove_element(tbl, el, cmp)
    cmp = cmp or function(a, b)
        return a == b
    end
    local idx = M.find_element(tbl, el, cmp)
    if idx > 0 then
        table.remove(tbl, idx)
    end
end

---@param key string
function M.simulate_keypress(key)
    api.nvim_feedkeys(api.nvim_replace_termcodes(key, true, false, true), "x", true)
end

---@param text string
function M.simulate_input(text)
    M.simulate_keypress("a" .. text)
end

---calculate the dimension of the floating window
---usage: calc_size(0.5, total_lines) for calculating height (50% of total editor height)
---@param size number
---@param viewport integer
function M.calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@param lhs string | string[]
---@param rhs string | fun()
---@param opts? table
function M.set_keymaps(lhs, rhs, opts)
    ---@type string[]
    local keys = type(lhs) == "table" and lhs or { lhs }
    for _, key in ipairs(keys) do
        vim.keymap.set("n", key, rhs, opts)
    end
end

---@param lhs string | string[]
function M.unset_keymaps(lhs)
    ---@type string[]
    local keys = type(lhs) == "table" and lhs or { lhs }
    for _, key in ipairs(keys) do
        vim.keymap.del("n", key, { buffer = globals.bufnr })
    end
end

---See :help 'guicursor'
---@param type SpeedTyperCursorStyle
---@param blinking boolean
---@return string
function M.create_cursor(type, blinking)
    local styles_to_vim_config = {
        ["block"] = "block",
        ["line"] = "ver30",
        ["underline"] = "hor25",
    }
    local cursor = ("i:%s"):format(styles_to_vim_config[type])

    if blinking then
        cursor = ("%s,%s"):format(cursor, "i:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor")
    end

    return cursor
end

---@param subcmd_arg_lead string
---@param tbl table<string, any>
---@return string[]
function M.get_map_option_completion(subcmd_arg_lead, tbl)
    local subcmd_args = {}
    for el, _ in pairs(tbl) do
        table.insert(subcmd_args, el)
    end
    return vim.iter(subcmd_args)
        :filter(function(arg)
            return arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
end

---@param subcmd_arg_lead string
---@return string[]
function M.get_bool_option_completion(subcmd_arg_lead)
    local subcmd_args = { "on", "off" }
    return vim.iter(subcmd_args)
        :filter(function(arg)
            return arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
end

---@param text string
function M.center_text(text, buff_width)
    local sep = string.rep(" ", math.floor((buff_width - #text) / 2))
    return string.format("%s%s%s", sep, text, sep)
end

--- returns all of the elements from <tbl> that match <pattern>
---@param tbl string[]
---@param pattern string
---@return string[]
function M.fuzzy_search(tbl, pattern)
    local results = {}
    for _, str in ipairs(tbl) do
        if str:match(pattern) then
            table.insert(results, str)
        end
    end
    return results
end

return M
