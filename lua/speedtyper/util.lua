local SpeedTyperUtil = {}
---notify user of an error
---@param msg string
function SpeedTyperUtil.error(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.ERROR, { title = "Speedtyper" })
    error(msg)
end

---@param msg string
function SpeedTyperUtil.info(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.INFO, { title = "Speedtyper" })
end

---@return integer
---@return integer
function SpeedTyperUtil.get_cursor_pos()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return line, col
end

--- HACK: compare two floats
---@param a number
---@param b number
---@return boolean
function SpeedTyperUtil.equals(a, b)
    return tostring(a) == tostring(b)
end

---@param n integer number of empty lines
---@param bufnr? integer
function SpeedTyperUtil.clear_buffer_text(n, bufnr)
    local repl = {}
    for _ = 1, n do
        table.insert(repl, "")
    end
    vim.api.nvim_buf_set_lines(bufnr or 0, 0, n, false, repl)
end

---@param file_path string
function SpeedTyperUtil.read_file(file_path)
    local reader = io.open(file_path, "r")
    if reader == nil then
        SpeedTyperUtil.error("Failed to read from the file: " .. file_path)
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

-- HACK: disable buffer modification by disabling all modifying keys
function SpeedTyperUtil.disable_buffer_modification()
    -- exit insert mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
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
        "n",
        "N",
        ".",
    }
    for _, key in pairs(keys_to_disable) do
        vim.keymap.set({ "n", "v" }, key, "<Nop>", { buffer = 0 })
    end
end

---@param str string
function SpeedTyperUtil.trim(str)
    return str:gsub("^%s+", ""):gsub("%s+$", "")
end

---@param str string
---@param sep? string
function SpeedTyperUtil.split(str, sep)
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
function SpeedTyperUtil.get_word_from_sentence(sentence, idx)
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
---@param eq? fun(a: any, b: any) : boolean returns true if elements are the same
---@return integer idx index of the element `el` or 0 if `tbl` does not contain `el`
function SpeedTyperUtil.find_element(tbl, el, eq)
    eq = eq or function(a, b)
        return a == b
    end
    for idx, val in ipairs(tbl) do
        if eq(val, el) then
            return idx
        end
    end
    return 0
end

---@param tbl table
---@param el any
---@param eq? fun(a: any, b: any) : boolean returns true if elements are the same
---@return boolean
function SpeedTyperUtil.tbl_contains(tbl, el, eq)
    eq = eq or function(a, b)
        return a == b
    end
    return SpeedTyperUtil.find_element(tbl, el, eq) > 0
end

---@param tbl table
---@param el any
---@param eq? fun(a: any, b: any) : boolean returns true if elements are the same
function SpeedTyperUtil.remove_element(tbl, el, eq)
    eq = eq or function(a, b)
        return a == b
    end
    local idx = SpeedTyperUtil.find_element(tbl, el, eq)
    if idx > 0 then
        table.remove(tbl, idx)
    end
end

---@param key string
function SpeedTyperUtil.simulate_keypress(key)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "x", true)
end

---@param text string
function SpeedTyperUtil.simulate_input(text)
    SpeedTyperUtil.simulate_keypress("a" .. text)
end

return SpeedTyperUtil
