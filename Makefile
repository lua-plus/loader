
default:
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
		-o build/loader.lua

install:
	cp "$(PREFIX)/build/loader.lua" "$(LUADIR)"

clean: 
	rm -r ./build