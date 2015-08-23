
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
# 
# 1. make reload-styles ...  start the reload server 
# 2. make watch-styles  ...  watch the directory
#  'make styles' will now be triggered by changes in dir
BUILD_DIR ?= build
STYLE_SRC_DIR := www/assets/styles
STYLE_MAIN := $(STYLE_SRC_DIR)/input.css
STYLE_STYLES := $(shell find $(STYLE_SRC_DIR) -name '*.css')
STYLE_IMPORTS := $(filter-out $(STYLE_MAIN),$(STYLE_STYLES))
STYLE_OUT_DIR := $(BUILD_DIR)/resources/styles
OUT_STYLES  :=  $(STYLE_OUT_DIR)/style.css
ANALYZE-CSS  :=  $(LOG_DIR)/analyze-css.json

#############################################################
styles: $(OUT_STYLES) $(ANALYZE-CSS)

analyze-css: $(LOG_DIR)/analyze-css.json

prior-metrics: $(LOG_DIR)/prior-analyze-css.json


phantomas: $(LOG_DIR)/phantomas.json

#@watch -q $(MAKE) styles
watch-styles:
	@watch $(MAKE) styles

#	@watch -q $(MAKE) styles

.PHONY:  watch-styles prior-metrics

#############################################################
$(OUT_STYLES): $(STYLE_INPUT) $(STYLE_IMPORTS)
	@mkdir -p $(@D)
	@echo  "MODIFY $@"
	@echo  "SRC  $< "
	@echo "PARAM 1 (route) :$(patsubst build/%,%,$(dir $@))"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file) :$(notdir $@)"
	@echo "IMPORT FROM $(dir  $<)"
	@node -pe "\
 var fs = require('fs');\
 var postcss   = require('postcss');\
 var autoprefixer   = require('autoprefixer');\
 var atImport = require('postcss-import');\
 var css = fs.readFileSync('$<', 'utf8');\
 postcss()\
 .use(atImport())\
 .use(autoprefixer())\
 .process(css).css" 2>  /dev/null > $@ && \
 xq store-files-from-pattern '$(patsubst build/%,%,$(dir $@))' '$(dir $(abspath $@))' '$(notdir $@)' 'text/css'  && \
 curl -s --ipv4 http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')


$(LOG_DIR)/analyze-css.json: $(OUT_STYLES)
	@echo  "analyze-css $@"
	@echo  "SRC  $< "
	@analyze-css --pretty --file $< > $@


$(LOG_DIR)/prior-analyze-css.json: $(LOG_DIR)/analyze-css.json
	@echo  "analyze-css"
	@node -pe "\
 R = require('./$(LOG_DIR)/analyze-css.json').metrics;" > $@

$(LOG_DIR)/analyze-css.json: $(OUT_STYLES)
	@echo  "analyze-css $@"
	@echo  "SRC  $< "
	@analyze-css --pretty --file $< > $@

$(LOG_DIR)/phantomas.json: $(OUT_STYLES)
	@echo  "analyze-css $@"
	@echo  "SRC  $< "
	@phantomas $(WEBSITE) --config=$(PHANTOMAS_CONFIG) --engine gecko --reporter tap
	@phantomas $(WEBSITE) --engine gecko --reporter json > $@

#$(LOG_DIR)/phantomas.json: $(OUT_STYLES)
#	@echo  "analyze-css $@"
#	@echo  "SRC  $< "
#	@phantomas $(WEBSITE) --config=$(PHANTOMAS_CONFIG) --engine gecko --reporter tap
#	@phantomas $(WEBSITE) --engine gecko --reporter json > $@

