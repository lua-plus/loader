
---@param str string
---@param s_end string | any
local function string_ends_with (str, s_end)
    s_end = tostring(s_end)

    return str:sub(-#s_end) == s_end 
end

return string_ends_with