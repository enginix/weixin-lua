.PHONY: local lint build

local: build
	luarocks make --local weixin-lua-dev-1.rockspec

build: 
	moonc payments lint_config.moon

lint:
	moonc -l payments
