local vanilla_require = require

--- env_aware_require acts the same as require(), except it reads/writes
--- _ENV.package.loaded instead of _G.package.loaded, and loads modules with
--- _ENV instead of _G (where _G is the original globals table, which Lua's
--- standard library uses instead of _ENV)
---@param modpath string
---@return any, string?
local function env_aware_require(modpath)
    local loaded = package.loaded[modpath]
    if loaded then
        return loaded
    end

    local c_path = package.searchpath(modpath, package.cpath)
    -- for C modules, just allow vanilla require behaviour
    if c_path then
        return vanilla_require(modpath)
    end

    local path, err = package.searchpath(modpath, package.path)

    if not path then
        error(err)
    end

    -- TODO does this work?
    ---@diagnostic disable-next-line:deprecated
    _ENV = _ENV or getfenv(2)

    local chunk, err = loadfile(path, nil, _ENV)

    if not chunk then
        error(err)
    end

    local mod = chunk(modpath, path)

    package.loaded[modpath] = mod

    return mod, path
end

local require = {}

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
        return env_aware_require(...)
    end
})

return require