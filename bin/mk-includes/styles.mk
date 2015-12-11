#==========================================================
#   STATIC ASSET PIPELINE for styles
#==========================================================
#
# make watch-styles  ...  watch the directory
#  'make styles' will now be triggered by changes in dir
#
# 1.  proccess css files -  using postcss into main.css build
#   - includes -  combined into one main build file
#   - cssnext  -
#   - autoprefixer
#  -  minification  strip comments etc
#
# 2. put built file into local dev server - log eXist server 'success' response
#
# 3.notify livereload server - :
#
#
##############################################################################
STYLE_SRC_DIR := resources/styles
STYLE_MAIN := $(STYLE_SRC_DIR)/main.css
STYLE_STYLES := $(shell find $(STYLE_SRC_DIR) -name '*.css')
STYLE_IMPORTS := $(filter-out $(STYLE_MAIN),$(STYLE_STYLES))
STYLE_OUT_DIR := $(BUILD_DIR)/resources/styles
OUT_STYLES  :=  $(STYLE_OUT_DIR)/main.css
ANALYZE_CSS  :=  $(LOG_DIR)/analyze-css.json
STYLES_STORED_LOG :=   $(LOG_DIR)/css-stored.log
STYLES_RELOADED_LOG :=  $(LOG_DIR)/css-reloaded.log
STYLES_TESTED :=   $(LOG_DIR)/phantomas.json
STYLES_UPLOADED_LOG :=   $(LOG_DIR)/css-uploaded.log

#############################################################
styles: $(OUT_STYLES) $(STYLES_STORED_LOG)  $(STYLES_RELOADED_LOG) $(STYLES_TESTED)


styles-help:
	@touch $(STYLE_MAIN)
	@echo styles help
	@echo $(call getMimeType,$(suffix test.css))
	@echo $(OUT_STYLES)
	@echo $(STYLES_STORED_LOG)
	@echo $(STYLES_RELOADED_LOG)

analyze-css: $(LOG_DIR)/analyze-css.json

prior-metrics: $(LOG_DIR)/prior-analyze-css.json

phantomas: $(LOG_DIR)/phantomas.json

#@watch -q $(MAKE) styles
watch-styles:
	@watch --interval 1 -q $(MAKE) styles

#	@watch -q $(MAKE) styles

.PHONY:  watch-styles test-styles

test-styles:
	@phantomas $(WEBSITE) --verbose --stop-at-onload --no-externals --colors --timeout=30 --config=$(PHANTOMAS_CONFIG) --reporter=tap


#############################################################
#
#  @cssfmt $< $@
# @cssnext --compress $(<) $@
#############################################################

$(OUT_STYLES): $(STYLE_MAIN) $(STYLE_IMPORTS)
	@echo "## $@ ##"
	@mkdir -p $(dir $@)
	@echo $@
	@echo "SRC  $< "
	@echo "collection_uri: $(dir $<)"
	@echo "directory: $(abspath $(dir $(addprefix build/,$<)))"
	@echo "pattern: $(notdir $<)"
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $<)))"
	@cssnext --compress $(<) $@
	@cssfmt $@
	@echo '-----------------------------------------------------------------'

$(STYLES_STORED_LOG): $(OUT_STYLES)
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC  $< "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join apps/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /resources/styles,,$(dir $<)))"
	@echo "eXist store pattern: : $(subst build/,,$<) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $<)))"
	@echo "log-name: $(basename $(notdir $@))"
	@xq store-built-resource \
 '$(join apps/,$(REPO))' '$(abspath  $(subst /resources/styles,,$(dir $<)))' \
 '$(subst build/,,$<)' '$(call getMimeType,$(suffix $(notdir $<)))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(STYLES_RELOADED_LOG): $(STYLES_STORED_LOG)
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo '-----------------------------------------------------------------'

$(STYLES_TESTED): $(STYLES_RELOADED_LOG)
	@echo "## $@ ##"
	@echo "prove with phantomas"
	@echo "input log: $<"
	@echo "$(WEBSITE)"
	@echo "output log: $@"
	@phantomas $(WEBSITE) --stop-at-onload --reporter json > $@
	@echo '-----------------------------------------------------------------'

$(LOG_DIR)/css-uploaded.log: $(OUT_STYLES)
	@echo  "css-uploaded $@"
	@echo  "SRC  $< "

$(LOG_DIR)/analyze-css.json: $(OUT_STYLES)
	@echo  "analyze-css $@"
	@echo  "SRC  $< "
	@analyze-css --pretty --file $< > $@
	@echo "$$(<$@)"

$(LOG_DIR)/prior-analyze-css.json: $(LOG_DIR)/analyze-css.json
	@echo  "analyze-css"
	@node -pe "\
 R = require('./$(LOG_DIR)/analyze-css.json').metrics;" > $@

