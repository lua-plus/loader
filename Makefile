
default: loader

loader:
	# https://github.com/Benjamin-Dobell/luabundler
	# luabundler can be installed via npm: 
	# npm i -g luabundler
	
	# bundle
	# isolated (no outside require())
	# with default path
	# to loader_bundle.lua
	luabundler bundle src/init.lua \
		-i \
		-p "./?.lua" -p "./?/init.lua" \
		-o $@

install: loader
	cp loader "$(INST_LUADIR)/luaplus-loader.lua"

clean: 
	rm loader
	rm luaplus-loader*.src.rock