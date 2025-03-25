---@param text string
local function string_escape(text)
    return text:gsub("([^%w])", "%%%1")
end

return string_escape