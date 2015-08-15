
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
#
# 1. make reload-styles ...  start the reload server
# 2. make watch-styles  ...  watch the directory
#  'make styles' will now be triggered by changes in dir
#  touch www/assets/icons/*
BUILD_DIR ?= build
ICONS_SRC_DIR := www/assets/icons
ICON_IMPORTS := $(shell find $(ICONS_SRC_DIR) -name '*.svg')
ICONS_OUT_DIR := $(BUILD_DIR)/resources/icons
ICONS_MAIN  :=  $(ICONS_OUT_DIR)/icons.svg

#############################################################
icons: $(ICONS_MAIN) $(XAR)

#@watch -q $(MAKE) icons
watch-icons:
	@watch -q $(MAKE) icons

.PHONY:  watch-icons
#############################################################
# icons
# make icons should
#
#############################################################
$(ICONS_MAIN):  $(ICON_IMPORTS)
	@mkdir -p $(@D)
	@echo  "MODIFY $@"
	@echo  "SRC  $< "
	@echo "PARAM 1 (route): $(patsubst build/%,%,$(dir $@))"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file): $(notdir $@)"
	@echo "IMPORT FROM: $(dir  $<)"
	@echo '<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">' \
 > .temp/temp.xml
	@cat $(ICON_IMPORTS) | sed -e 's% xmlns="http://www.w3.org/2000.svg"%%g' \
 | sed -e 's%<svg%<symbol%g' \
 | sed -e 's%</svg%</symbol%g' \
 | sed -e 's%</svg%</symbol%g' \
 | sed -e 's% fill="currentcolor"%%g' \
 >> .temp/temp.xml
	@echo '</svg>'  >> .temp/temp.xml
	@node -pe "\
 fs = require('fs');\
 var n = require('cheerio').load( fs.readFileSync('.temp/temp.xml', 'utf-8')  ,{normalizeWhitespace: false,xmlMode: true});\
 ;n.xml()" > $@ && \
 xq store-files-from-pattern '$(patsubst build/%,%,$(dir $@))' '$(dir $(abspath $@))' '$(notdir $@)' 'application/xml'

