
OR_SITE := $(OPENRESTY_HOME)/site/lualib/$(ABBREV)
SRC_LUA := $(shell find lua-modules -name '*.lua' )
LUA_MODULES  := $(patsubst lua-modules/%,$(OR_SITE)/%,$(SRC_LUA))

lua-modules: $(LUA_MODULES)

watch-lua-modules:
	@watch -q $(MAKE) lua-modules

.PHONY:  watch-lua-modules 

$(OR_SITE)/%:lua-modules/%
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo "SRC: $<" 
	@echo 'copied files into openresty  directory'
	@cp $< $@
	@echo '-----------------------------------------------------------------'

#$(info $(LUA_MODULES))
#$(info $(SRC_LUA))
#$(info $(OR_SITE))
