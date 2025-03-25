local table_crush = require("src.polyfill.table.crush")
local pattern     = require("src.polyfill.pattern")
local path        = require("src.polyfill.path")
local fs          = require("src.polyfill.fs")
local ends_with   = require("src.polyfill.string.ends_with")
local split       = require("src.polyfill.string.split")

---@class LuaPlus.Searcher.Alias
---@field [1] string|fun(str: string): string
---@field [2] fun(modname: string): string|string[]


local searcher = {}


-- TODO make readonly
-- default aliases
searcher.default_alises = {
    -- relative matching
    { pattern("^(%.+)"), function(_, this, post)
        -- TODO implement differently if transforming as a macro
        local info = nil
        for idx = 5, 16 do
            info = debug.getinfo(idx)

            if info.source ~= "=[C]" then
                break
            end
        end

        local this_mod = path.dirname(info.source:sub(2))
            -- remove any leading slash
            :gsub("%.[/\\]", "")
            -- replace slash with dot
            :gsub("[/\\]", "")
        -- add trailing dot if nonempty

        local full_path = this_mod .. this .. post

        if full_path:match("^%.") then
            -- this is a lie low key
            error("Cannot match relative beyond root directory")
        end

        full_path = full_path:gsub("[^%.]+%.%.", "")

        return full_path
    end },

    -- wildcard matching
    fs and { "%.%*", function(pre, _, post)
        local paths = package.path .. ";" .. package.cpath

        local modules = {}
        for search_path in paths:gmatch("[^;]+") do
            search_path = search_path:gsub("%?[/\\]?.-%..*", "")

            if not ends_with(search_path, "loadall.so") then
                local pre_path = pre:gsub("%.", path.sep)
                local pre_path = path.join(search_path, pre_path)

                if fs.exists(pre_path) and fs.is_dir(pre_path) then
                    for _, file in ipairs(fs.ls(pre_path)) do
                        -- remove extension
                        local file_mod = file:gsub("%..*$", "")

                        local module = pre .. "." .. file_mod .. post

                        modules[module] = true
                    end
                end
            end
        end

        -- Convert module=true to [i]=module
        local ret = {}
        for k in pairs(modules) do
            table.insert(ret, k)
        end
        return ret
    end },

    -- match multiple files
    { "%(([^%)]+)%)", function(pre, _, post, modules)
        local files = split(modules, "|")

        local modules = {}
        for _, file in ipairs(files) do
            table.insert(modules, pre .. file .. post)
        end

        return modules
    end }
}


searcher.aliases = table_crush(searcher.default_alises)

---@param aliases LuaPlus.Searcher.Alias[]
function searcher.create(aliases)
    ---@param modname string
    return function(modname)
        -- Permute modnames via aliases
        for _, alias in ipairs(aliases) do
            local pattern, replacer = table.unpack(alias)
        end
    end
end

local default_searcher = searcher.create(searcher.aliases)

setmetatable(searcher, {
    __call = function(_, ...)
        return default_searcher(...)
    end
})

return searcher
