
default:
	# https://github.com/Benjamin-Dobell/luabundler
	# luabundler can be installed via npm: 
	# npm i -g luabundler

	ifeq (, $(shell which luabundler))
		$(error "No luabundler in PATH. run $ npm i -g luabundler")
	endif


	# bundle
	# isolated (no outside require())
	# with default path
	# to loader_bundle.lua
	luabundler bundle src/init.lua \
		-i \
		-p "./?.lua" -p "./?/init.lua" \
		-o build/loader.lua

install:
	cp "build/loader.lua" "$(INST_LUADIR)/luaplus-loader.lua"

clean: 
	rm -r ./build