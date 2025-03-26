
local luaplus_require = require("src.require")
local luaplus_searcher = require("src.searcher")

local loader = {}

loader.searcher = luaplus_searcher
loader.require = luaplus_require

loader.pattern = require("src.polyfill.pattern")

function loader.register ()
    _G.require = luaplus_require

    luaplus_searcher.register()
end

return loader