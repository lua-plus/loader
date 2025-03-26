package = "luaplus-loader"
version = "0.1.0-1"
source = {
   url = "https://github.com/lua-plus/loader"
}
description = {
   -- homepage = "*** please enter a project homepage ***",
   license = "GNU GPLv3"
}
build = {
   type = "make",
   modules = {
      ["loader"] = "build/loader.lua"
   }
}
