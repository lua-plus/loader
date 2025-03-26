local table_unpack = require("src.polyfill.table.unpack")
local table_pack   = require("src.polyfill.table.pack")

---@alias matcher fun(str: string, init?: integer): integer?, integer?, ...: string

---@class pattern
---@field pat string
local pattern      = {}

function pattern.pattern(pat)
    local self = {}
    self.pat = pat
    setmetatable(self, getmetatable(pattern))

    return self
end

---@param self pattern | string
---@param str string
---@param init integer?
---@return integer?, integer?, string ...
function pattern:exec(str, init)
    local ret = table_pack(pattern.find(self, str, init))

    local m_start, m_end = table_unpack(ret, 1, 2)

    if not (m_start and m_end) then
        return nil
    end

    local matches = #ret > 2 and
        { table_unpack(ret, 3) } or
        { str:sub(m_start, m_end) }

    return m_start, m_end, table_unpack(matches)
end

---@param self pattern | string
---@param str string
---@param init integer?
function pattern.find(self, str, init)
    if type(self) == "string" then
        return string.find(str, self, init)
    end

    return string.find(str, self.pat, init)
end

---@param self pattern | string
---@param str string
---@param init integer?
---@return integer?, integer?, string[]?
function pattern.find_packmatch(self, str, init)
    local ret = table_pack(pattern.find(self, str, init))

    local m_start, m_end = table_unpack(ret, 1, 2)
    local matches = table_pack(table_unpack(ret, 3))

    return m_start, m_end, matches
end

function pattern.tostring(self)
    if self == pattern then
        return "pattern namespace"
    else
        return self.pat
    end
end

setmetatable(pattern, {
    __call = function(t, ...)
        if t == pattern then
            return pattern.pattern(...)
        else
            return pattern.exec(t, ...)
        end
    end,
    __tostring = pattern.tostring,
    __index = pattern,
})

return pattern
