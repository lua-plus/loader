local table_crush  = require("src.polyfill.table.crush")
local pattern      = require("src.polyfill.pattern")
local path         = require("src.polyfill.path")
local ends_with    = require("src.polyfill.string.ends_with")
local split        = require("src.polyfill.string.split")
local table_pack   = require("src.polyfill.table.pack")
local table_unpack = require("src.polyfill.table.unpack")
local transpose    = require("src.polyfill.matrix.transpose")
local fs_is_dir       = require("src.polyfill.fs.is_dir")
local fs_ls            = require("src.polyfill.fs.ls")
local fs_exists          = require("src.polyfill.fs.exists")

---@alias LuaPlus.Searcher.Permuter fun(pre: string, match: string, post: string, ...:string ): string|string[]

---@class LuaPlus.Searcher.Alias
---@field [1] string|fun(str: string): string
---@field [2] string|LuaPlus.Searcher.Permuter


---@class LuaPlus.Searcher
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
            :gsub("[/\\]", ".")

        local full_path = this_mod .. this .. post

        if full_path:match("^%.") then
            -- this is a lie low key
            error("Cannot match relative beyond root directory")
        end

        full_path = full_path:gsub("[^%.]+%.%.", "")

        return full_path
    end },

    -- wildcard matching
    { pattern("%.%*"), function(pre, _, post)
        local paths = package.path .. ";" .. package.cpath

        local modules = {}
        for search_path in paths:gmatch("[^;]+") do
            search_path = search_path:gsub("%?[/\\]?.-%..*", "")

            if not ends_with(search_path, "loadall.so") then
                local pre_path = pre:gsub("%.", path.sep)
                local pre_path = path.join(search_path, pre_path)

                if fs_exists(pre_path) and fs_is_dir(pre_path) then
                    for _, file in ipairs(fs_ls(pre_path)) do
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
        table.sort(ret)
        return ret
    end },

    -- match multiple files
    { pattern("%(([^%)]+)%)"), function(pre, _, post, modules)
        local files = split(modules, "|")

        local modules = {}
        for _, file in ipairs(files) do
            table.insert(modules, pre .. file .. post)
        end

        return modules
    end }
}


searcher.aliases = table_crush(searcher.default_alises)


---@protected
---@param replacer string | function
---@param modname string
---@param m_start integer
---@param m_end integer
---@param matches string[]
---@return string[]
function searcher._call_replacer(replacer, modname, m_start, m_end, matches)
    local pre = modname:sub(1, m_start - 1)
    local match = modname:sub(m_start, m_end)
    local post = modname:sub(m_end + 1)

    if type(replacer) == "string" then
        return { pre .. replacer .. post }
    end

    local returns = replacer(pre, match, post, table_unpack(matches))

    if type(returns) == "table" then
        return returns
    end

    return { tostring(returns) }
end

---@protected
---@param p string | pattern
---@param modname string
---@param search_init integer
---@return integer?, integer?, string[]?
function searcher._match_pattern (p, modname, search_init)
    if type(p) == "string" then
        for i=1,#modname do
            local j = i + #p - 1

            if modname:sub(i, j) == p then
                return i, j, {}
            end
        end

        return nil, nil, nil
    else
        return pattern.find_packmatch(p, modname, search_init)
    end
end


---@protected
---@param modnames string[]
---@param p string | pattern
---@param replacer string | function
---@param search_init integer?
function searcher._permute(modnames, p, replacer, search_init)
    search_init = search_init or 1

    local new_modnames = {}
    for _, modname in pairs(modnames) do
        local m_start, m_end, matches = searcher._match_pattern(p, modname, search_init)

        if not (m_start and m_end and matches) then
            table.insert(new_modnames, modname)
        else
            for _, new_modname in ipairs(searcher._call_replacer(
                replacer, modname, m_start, m_end, matches
            )) do
                local further_permutations = searcher._permute(
                    { new_modname }, p, replacer, m_end)

                for _, new_modname in ipairs(further_permutations) do
                    table.insert(new_modnames, new_modname)
                end
            end
        end
    end

    return new_modnames
end

---@protected
function searcher._as_searcher_return(returns)
    if #returns == 1 then
        local ret = returns[1]
        local mod = ret[1]

        local get_module = function() return mod end

        return get_module, table_unpack(ret, 2)
    end

    -- Transpose returns - now we have column lists
    local t = transpose(returns)

    local modules = t[1]

    local get_modules = function() return modules end

    return get_modules, table_unpack(t, 2)
end

---@param aliases LuaPlus.Searcher.Alias[]
function searcher.create(aliases)
    ---@param modname string
    return function(modname)
        local modnames = { modname }

        -- Permute modnames via aliases
        for _, alias in ipairs(aliases) do
            local pattern = alias[1]
            local replacer = alias[2]

            -- TODO fix typing hint here.
            local new_modnames = searcher._permute(modnames, pattern, replacer)

            if #new_modnames ~= 0 then
                modnames = new_modnames
            end
        end

        -- return if modnames hasn't changed in any way, ie it was not permuted.
        if #modnames == 1 and modnames[1] == modname then
            return
        end

        -- load all requested modules
        local returns = {}
        for i, modname in ipairs(modnames) do
            -- TODO include matching data in loader data - requires that we change searcher._permute
            returns[i] = table_pack(_G.require(modname))
        end

        return searcher._as_searcher_return(returns)
    end
end

local default_searcher = searcher.create(searcher.aliases)

---@param searcher function?
function searcher.register(searcher)
    searcher = searcher or default_searcher

    ---@diagnostic disable-next-line:deprecated
    local searchers = package.loaders or package.searchers

    for _, v in ipairs(searchers) do
        if v == searcher then
            return
        end
    end

    table.insert(searchers, searcher)
end

setmetatable(searcher, {
    __call = function(_, ...)
        return default_searcher(...)
    end
})

return searcher
