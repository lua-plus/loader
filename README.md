
# The Lua Plus loader

The Lua Plus loader aims to improve the behavior of lua's module loading
facilities for large and small projects alike. It features an improved, 
but vanilla-compatible implementation of `require()`, and facilities for
writing package searchers. 

It aims to support LuaJIT, Lua 5.3, and Lua 5.4, though only Lua 5.4 has been
tested thus far.

## Quick start

If you wish to use the Lua Plus loader without manual configuration, simply
include the code below in your project:
```lua
local luaplus_loader = require("luaplus.loader")

-- This function replaces require() with a slightly improved version, and 
-- installs the default searcher with default aliases
luaplus_loader.register()
```

Calls to `require()` will now respect the current `_ENV`, whereas Lua's default
relies on `_G`. This may not work correctly in all execution contexts, such as
the web.

Additionally, the Lua Plus loader includes aliases for relative requires
(eg, `require(".neighbor_module")`), wildcard matches (eg, `require("util.fs.*")`), and
loading multiple files (eg, `require("util.fs.(ls|mkdir)")`)


## Extending the searcher

The Lua Plus searcher is designed to be easily extended. New searcher 'aliases'
can be added to the default searcher by inserting to the `searcher.aliases`
table. 

An alias is a 2-element table where the first element is a matcher 
string or a `pattern` object. The `pattern` object signifies to the searcher 
that this alias is a Lua pattern, and not plaintext to compare against. The
second element is a replacer, which can take the form of either a string or
function. 

If a function is provided, it is called with the arguments `pre, match, post,
...capture`. `pre`, `match`, and `post` are the previous text segment to the
match, the pattern's match itself, and the text after, respectively. Capture
groups are passed afterwards, as variadic arguments. Replacer functions may 
return a string or list of strings.

### Searcher Example

```lua
local loader = require("luaplus-loader")
local searcher = loader.searcher
local pattern = loader.pattern


searcher.register()

local alias = { pattern("^~lib"), "./lua_modules/" }
table.insert(searcher.aliases, alias)
```