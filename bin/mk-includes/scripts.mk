
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
BUILD_DIR ?= build
SRC_SCRIPTS := $(shell find www/resources/scripts -name '*.js')
SCRIPTS_BUILD_DIR := $(BUILD_DIR)/resources/scripts

JS_SCRIPTS := $(patsubst www/resources/scripts/%, $(SCRIPTS_BUILD_DIR)/%, $(SRC_SCRIPTS))
#############################################################
scripts: $(JS_SCRIPTS)

#for testing  use: make watch-templates
watch-scripts:
	@watch -q $(MAKE) scripts

.PHONY:  watch-scripts
#############################################################

# Copy over templates
$(SCRIPTS_BUILD_DIR)/%: www/assets/scripts/%
	@mkdir -p $(@D)
	@echo "PARAM 1 (route) :$(dir $<)"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file) :$(notdir $@)"
	@cp $< $@
	xq store-files-from-pattern \
 '$(patsubst build/%,%,$(dir $@))' \
 '$(dir $(abspath $@))' '$(notdir $@)' \
 'application/x-javascript'  && \
 curl \
 -s \
 --ipv4 \
 http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')
