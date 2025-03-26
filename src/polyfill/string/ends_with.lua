
---@param str string
---@param suffix string | any
local function string_ends_with (str, suffix)
    suffix = tostring(suffix)

    return str:sub(-#suffix) == suffix 
end

return string_ends_with