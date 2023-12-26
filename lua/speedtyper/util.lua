local SpeedTyperUtil = {}
---notify user of an error
---@param msg string
function SpeedTyperUtil.error(msg)
    -- "\n" for nvim configs that don't use nvim-notify
    vim.notify("\n" .. msg, vim.log.levels.WARN, { title = "Speedtyper" })
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
---@return string[]
function SpeedTyperUtil.clear_text(n)
    local repl = {}
    for _ = 1, n do
        table.insert(repl, "")
    end
    return repl
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

---@param tbl table
---@param el any
---@param eq fun(a: any, b: any) : boolean returns true if elements are the same
---@return integer idx index of the element `el` or 0 if `tbl` does not contain `el`
function SpeedTyperUtil.find_element(tbl, el, eq)
    for idx, val in ipairs(tbl) do
        if eq(val, el) then
            return idx
        end
    end
    return 0
end

---@param tbl table
---@param el any
---@param eq fun(a: any, b: any) : boolean returns true if elements are the same
function SpeedTyperUtil.remove_element(tbl, el, eq)
    local idx = SpeedTyperUtil.find_element(tbl, el, eq)
    if idx > 0 then
        table.remove(tbl, idx)
    end
end

return SpeedTyperUtil
