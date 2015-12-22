
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
