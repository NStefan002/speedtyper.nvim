local api = vim.api

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

---NOTE: currently unused, but might be useful when we add stories and other text features
---@param file_path string
---@return string[]
function M.read_words_from_file(file_path)
    local reader = io.open(file_path, "r")
    if reader == nil then
        M.error("Failed to read from the file: " .. file_path)
        return {}
    end

    local words = {}
    for line in reader:lines("*l") do
        for word in string.gmatch(line, "%S+") do
            table.insert(words, word)
        end
    end

    reader:close()
    return words
end

---@param bufnr integer
function M.disable_buffer_modification(bufnr)
    -- exit insert mode
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "!", true)
    api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---@param str string
---@return string
function M.trim(str)
    local result, _ = str:gsub("^%s+", ""):gsub("%s+$", "")
    return result
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
---@param bufnr? integer
function M.unset_keymaps(lhs, bufnr)
    local opts = bufnr and { buffer = bufnr } or {}
    ---@type string[]
    local keys = type(lhs) == "table" and lhs or { lhs }
    for _, key in ipairs(keys) do
        vim.keymap.del("n", key, opts)
    end
end

---See :help 'guicursor'
---@param type speedtyper.cursor_style
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
    local text_len = api.nvim_strwidth(text)
    local sep = string.rep(" ", math.floor((buff_width - text_len) / 2))
    return string.format("%s%s%s", sep, text, sep)
end

---@return string
function M.get_plugin_path()
    local paths = api.nvim_list_runtime_paths()
    for _, str in ipairs(paths) do
        if str:match(".*speedtyper.nvim$") then
            return str
        end
    end
    return ""
end

---Read files from a directory, optionally filtering by extension
---and removing the extension from the file name
---@param dir string Directory to read files from
---@param ext? string If provided, only files with this extension will be returned
---@param remove_ext? boolean If true, the extension will be removed from the file name
---@return string[]
function M.read_dir(dir, ext, remove_ext)
    ext = (ext or "") .. "$"

    local dir_handle, _, _ = vim.uv.fs_opendir(dir)
    if dir_handle == nil then
        return {}
    end

    local entries = {}
    local entry, _, _ = dir_handle:readdir()
    while entry ~= nil do
        table.insert(entries, entry[1])
        entry, _, _ = dir_handle:readdir()
    end
    dir_handle:closedir()

    local files_without_ext = vim.iter(entries)
        :filter(function(e)
            -- return only files
            return e.type == "file"
        end)
        :map(function(e)
            -- remove extension only if `remove_ext` is true
            if not remove_ext then
                return e.name
            end
            local str, _ = e.name:gsub(ext, "")
            return str
        end)
        :totable()

    table.sort(files_without_ext)

    return files_without_ext
end

---Get the character at the given index in a utf-8 string
---@param str string
---@param idx integer if negative, index from the end of the string (-1 is the last character)
---@return string
function M.utf_char_at(str, idx)
    local utf_indices = vim.str_utf_pos(str)
    if idx == 0 or idx > #utf_indices then
        return ""
    end
    if idx < 0 then
        idx = #utf_indices + idx + 1
    end
    return str:sub(utf_indices[idx], idx < #utf_indices and utf_indices[idx + 1] - 1 or -1)
end

---find the index of a character in a utf-8 string
---@param str string utf-8 string
---@param char string character to search for
---@param start? integer index to start searching from (indicies are the positions of utf-8 characters, not bytes as in default lua strings)
---@return integer
function M.utf_find(str, char, start)
    if api.nvim_strwidth(char) ~= 1 then
        M.error("Only single-char strings are supported")
        return -1
    end
    local utf_indices = vim.str_utf_pos(str)
    local start_idx = utf_indices[start] or 1
    local char_idx, _, _ = str:find(char, start_idx, true)
    if char_idx == nil then
        return -1
    end
    for i, idx in ipairs(utf_indices) do
        if idx == char_idx then
            return i
        end
    end
    return -1
end

---get a substring of a utf-8 string
---@param str string
---@param start integer index of the first character of the substring (indicies are the positions of utf-8 characters, not bytes as in default lua strings)
---@param stop? integer if nil, the substring will be from `start` to the end of the string
---@return string
function M.utf_sub(str, start, stop)
    local utf_indices = vim.str_utf_pos(str)

    if start > #utf_indices then
        return ""
    end
    if start < 0 then
        start = #utf_indices + start + 1
    end
    local start_idx = utf_indices[start] or 1

    stop = stop or #utf_indices
    if stop < 0 then
        stop = #utf_indices + stop + 1
    end
    local stop_idx = (utf_indices[stop + 1] or 0) - 1

    return str:sub(start_idx, stop_idx)
end

---reads the json file and returns the lua table
---@param file_path string
---@return table
function M.read_json(file_path)
    local reader = io.open(file_path, "r")
    if reader then
        local content = reader:read("*a")
        reader:close()
        return vim.json.decode(content) or {}
    else
        M.error(("Failed to read from file: %s"):format(file_path))
    end
    return {}
end

---@param name string
---@param val vim.api.keyset.highlight
function M.hl(name, val)
    val.cterm = val.cterm or {}
    api.nvim_set_hl(require("speedtyper.globals").ns_id, name, val)
end

return M
