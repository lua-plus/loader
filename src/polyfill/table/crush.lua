
local table_pack = require("src.polyfill.table.pack")

--- Create a table whose values are defined by each table in ..., in order.
---@generic T
---@param ... T
---@return T
local function table_crush (...)
    local ret = {}

    for _, t in ipairs(table_pack(...)) do
        for k, v in pairs(t) do
            ret[k] = v
        end
    end

    return ret
end

return table_crush