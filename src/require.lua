local vanilla_require = require
local searcher        = require "src.searcher"

---@class LuaPlus.Require
local require = {}

---@protected
---@param modname string
---@return string? path, string? error
function require._find_path (modname)
    ---@diagnostic disable-next-line:deprecated
    local searchers = package.loaders or package.searchers

    for _, s in ipairs(searchers) do
        -- check if this is a luaplua-loader searcher
        local aliases = searcher.instances[s]
        
        if aliases then
            local modnames = searcher.permute_aliases(modname, aliases)

            for _, modname in ipairs(modnames) do
                local path = package.searchpath(modname, package.path)

                if path then
                    return path
                end
            end
        end
    end

    local path, err = package.searchpath(modname, package.path)

    return path, err
end

---@param modname string
---@param env table?
---@return any, string?
function require.with_env (modname, env)
    -- TODO does this work?
    ---@diagnostic disable-next-line:deprecated
    env = env or _ENV or getfenv(2)

    local loaded = package.loaded[modname]
    if loaded then
        return loaded
    end

    local c_path = package.searchpath(modname, package.cpath)
    -- for C modules, just allow vanilla require behaviour
    if c_path then
        return vanilla_require(modname)
    end

    local path, err = require._find_path(modname)

    if not path then
        error(err)
    end

    local chunk, err = loadfile(path, nil, env)

    if not chunk then
        error(err)
    end

    if _VERSION <= "Lua 5.1" then
        ---@diagnostic disable-next-line:deprecated
        setfenv(chunk, env)
    end

    local mod = chunk(modname, path)

    package.loaded[modname] = mod

    return mod, path
end

--[[
function require.isolated(...)
    local env = setmetatable({
        package = setmetatable({
            loaded = {
                math = math,
                table = table,
                string = string,
                coroutine = coroutine,
                package = package,
                utf8 = utf8,
                _G = _G,
                debug = debug,
                io = io,
                os = os,
            }
        }, { __index = package }),
        require = env_aware_require
    }, { __index = _G })

    if _ENV then
        _ENV = env
    else
        -- TODO does this work?
        ---@diagnostic disable-next-line:deprecated
        setfenv(require.isolated, env)
    end

    return env_aware_require(...)
end
]]

setmetatable(require, {
    __call = function(_, ...)
        return require.with_env(...)
    end
})

return require