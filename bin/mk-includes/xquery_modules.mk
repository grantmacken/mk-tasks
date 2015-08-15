#==========================================================
#  XQUERY MODULES
#==========================================================
SRC_MODULES := $(shell find modules -name '*.xq*' )
MODULES_BUILD_DIR := $(BUILD_DIR)/modules
XQUERY_MODULES := $(patsubst modules/%, $(MODULES_BUILD_DIR)/%, $(SRC_MODULES))
#############################################################
modules: $(XQUERY_MODULES)

#for testing  use: make watch-modules
watch-modules:
	@watch -q $(MAKE) modules

.PHONY:  watch-modules

#############################################################

# Copy over xquery modules
$(MODULES_BUILD_DIR)/%: modules/%
	@mkdir -p $(@D)
	@echo "PARAM 1 (route) :$(dir $<)"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file) :$(notdir $@)"
	@cp $< $@
	xq store-files-from-pattern '$(patsubst build/%,%,$(dir $@))' '$(dir $(abspath $@))' '$(notdir $@)' 'application/xquery'  && \
 curl -s --ipv4 http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')
