
-- TODO FIXME currently unused.

--- swap two tables while maintaining their references 
---@param t1 table
---@param t2 table
local function ptr_swap (t1, t2)
    local tmp = {}

    -- copy t1 to tmp
    for k, v in pairs(t1) do
        tmp[k] = v
    end
    setmetatable(tmp, getmetatable(t1))

    -- copy t2 to t1
    for k, v in pairs(t2) do
        t1[k] = v
    end
    setmetatable(t1, getmetatable(t2))

    -- copy tmp to t2
    for k, v in pairs(tmp) do
        t2[k] = v
    end
    setmetatable(t2, getmetatable(t2))
end

return ptr_swap