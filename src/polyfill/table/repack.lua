
local table_pack = require("src.polyfill.table.pack")
local table_unpack = require("src.polyfill.table.unpack")

--- Return a new table, consisting of t[i..j]
---@param t table
---@param i integer?
---@param j integer?
local function table_repack (t, i, j)
    return table_pack(table_unpack(t, i, j))
end

return table_repack