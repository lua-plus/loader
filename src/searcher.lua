--[[
    LuaPlus searcher. Allows creating aliases using strings or functions
]]

-- TODO export read-only default alias list (optional), and alias generation helpers, etc.

local escape = require("src.polyfill.string.escape")
local ends_with    = require("src.polyfill.string.ends_with")
local transpose = require("src.polyfill.matrix.transpose")
local path         = require("src.polyfill.path")
local fs           = require("src.polyfill.fs.fs")
local split        = require("src.polyfill.string.split")

-- TODO BundleableSearcher class
--  - one callback for module to path
--  - one callback for path to lua source
--  - one callback for lua source to program 
-- all with nice defaults
-- now people can build their own!

local aliases = {
    { escape("~NativeElement"), "example.dir.NativeElement" },

    -- relative matching
    { "^(%.+)", function(_, this, post)
        -- TODO implement differently if transforming as a macro
        local info = nil
        for idx=5, 16 do
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
            -- TODO this is a lie low key
            error("Cannot match relative beyond root directory")
        end

        full_path = full_path:gsub("[^%.]+%.%.", "")

        return full_path
    end },

    -- wildcard matching
    { "%.%*", function (pre, _, post)
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
    { "%(([^%)]+)%)", function (pre, _, post, modules)
        local files = split(modules, "|")

        local modules = {}
        for _, file in ipairs(files) do
            table.insert(modules, pre .. file .. post)
        end

        return modules
    end }
}

---@alias SearchPlus.SearchFunction fun(pre: string, this: string, post: string, ...:string ): string|string[]

-- TODO allow a pattern matcher that sets a soft require flag

-- TODO never breaks if the callback does nothing
--- permute a matched pattern via a function, for any occurence.
---@param modnames string[]
---@param pattern string
---@param replacer SearchPlus.SearchFunction
---@param match_start integer?
local function permute_multisub_function(modnames, pattern, replacer, match_start)
    match_start = match_start or 1

    local new_modnames = {}
    for _, modname in pairs(modnames) do
        local ret = table.pack(modname:find(pattern, match_start))

        local s_start, s_end = table.unpack(ret, 1, 2)

        if not (s_start and s_end) then
            table.insert(new_modnames, modname)
            
            break
        end

        local pre = modname:sub(1, s_start - 1)
        local match = modname:sub(s_start, s_end)
        local post = modname:sub(s_end + 1)

        local replaced_list = replacer(pre, match, post, table.unpack(ret, 3))

        if type(replaced_list) ~= "table" then
            replaced_list = { replaced_list }
        end

        for _, replaced in ipairs(replaced_list) do
            -- re-permute further down the string
            local further_permutations = permute_multisub_function({ replaced }, pattern, replacer, s_end)

            for _, modname in ipairs(further_permutations) do
                table.insert(new_modnames, modname)
            end
        end
    end

    return new_modnames
end

---@param modnames string[]
---@param pattern string
---@param replacer string | function
local function permute_multisub(modnames, pattern, replacer)
    local new_modnames = {}
    if type(replacer) == "string" then
        for _, modname in ipairs(modnames) do
            -- TODO would there be a reason to permute w/ replacer?
            local new_modname = modname:gsub(pattern, replacer)

            table.insert(new_modnames, new_modname)
        end
    elseif type(replacer) == "function" then
        local permuted_list = permute_multisub_function(modnames, pattern, replacer)

        for _, permuted in ipairs(permuted_list) do
            table.insert(new_modnames, permuted)
        end
    end

    return new_modnames
end

---@param modname string
local searcher = function(modname)
    -- Permute modnames
    local modnames = { modname }
    for _, alias in ipairs(aliases) do
        local pattern, replacer = table.unpack(alias)

        modnames = permute_multisub(modnames, pattern, replacer)
    end

    -- return if modnames hasn't changed in any way, ie it was not permuted.
    if #modnames == 1 and modnames[1] == modname then
        return
    end

    -- load all modules requested
    local rets = {}
    for i, modname in ipairs(modnames) do
        local ret = table.pack(require(modname))

        rets[i] = ret
    end


    if #rets == 1 then
        local mod = rets[1][1]

        local get_module = function()
            return mod
        end

        return get_module, table.unpack(rets[1], 2)
    else

        local t = transpose(rets)

        local get_modules = function()
            return t[1]
        end

        return get_modules, table.unpack(t, 2)
    end
end

return searcher
