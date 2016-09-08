
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
#
# 1. make reload-styles ...  start the reload server
# 2. make watch-styles  ...  watch the directory
#  'make styles' will now be triggered by changes in dir
#  touch www/assets/icons/*
ICON_IMPORTS := $(shell find resources/icons -name '*.svg')

#############################################################
$(info $(SCRIPTS) )

icons: $(L)/icons-reloaded.log

#@watch -q $(MAKE) icons
watch-icons:
	@watch -q $(MAKE) icons

.PHONY:  watch-icons
#############################################################
# icons
# make icons should
#
#############################################################
$(B)/resources/icons/icons.svg:  $(ICON_IMPORTS)
	@echo "## $@ ##"
	@mkdir -p $(dir $@)
	@echo $@
	@echo "SRC  $< "
	@echo "collection_uri: $(dir $<)"
	@echo "directory: $(abspath $(dir $(addprefix build/,$<)))"
	@echo "pattern: $(notdir $<)"
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $<)))"
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
 ;n.xml()" > $@ 

$(L)/icons-stored.log: $(B)/resources/icons/icons.svg
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC  $< "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join apps/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /resources/icons,,$(dir $<)))"
	@echo "eXist store pattern: : $(subst build/,,$<) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $<)))"
	@echo "log-name: $(basename $(notdir $@))"
	@xq store-built-resource \
 '$(join apps/,$(REPO))' '$(abspath  $(subst /resources/icons,,$(dir $<)))' \
 '$(subst build/,,$<)' '$(call getMimeType,$(suffix $(notdir $<)))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(L)/icons-reloaded.log: $(L)/icons-stored.log
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo '-----------------------------------------------------------------'
