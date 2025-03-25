
---@generic T
---@param A T[][]
---@return T[][]
local function transpose (A)
    local ret = {}

    -- 0xn returns immediately
    if #A == 0 then
        return ret
    end

    for r, col in ipairs(A) do
        for i=1, #col do
            if ret[i] == nil then
                ret[i] = {}
            end
        end

        for c, value in ipairs(col) do
            ret[c][r] = value
        end
    end

    return ret
end

return transpose