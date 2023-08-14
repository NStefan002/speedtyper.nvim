local M = {}

---@param size integer | float
---@param viewport integer
function M.calc_size(size, viewport)
    if size <= 1 then
        return math.ceil(size * viewport)
    end
    return math.min(size, viewport)
end

---@param words table<string>
---@return string
function M.generate_sentence(words)
    -- put random words together into a sentence and make it about 80 chars
    math.randomseed(os.time())
    local sentence = words[math.random(1, #words)]
    local len = #sentence
    while len <= 80 do
        local word = words[math.random(1, #words)]
        sentence = sentence .. " " .. word
        len = len + #word
    end
    return sentence
end

return M
