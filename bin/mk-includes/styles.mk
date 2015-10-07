#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
# 
# 1. make reload-styles ...  start the reload server 
# 2. make watch-styles  ...  watch the directory
#  'make styles' will now be triggered by changes in dir
BUILD_DIR ?= build
STYLE_SRC_DIR := www/resources/styles
STYLE_MAIN := $(STYLE_SRC_DIR)/main.css
STYLE_STYLES := $(shell find $(STYLE_SRC_DIR) -name '*.css')
STYLE_IMPORTS := $(filter-out $(STYLE_MAIN),$(STYLE_STYLES))
STYLE_OUT_DIR := $(BUILD_DIR)/resources/styles
OUT_STYLES  :=  $(STYLE_OUT_DIR)/style.css
ANALYZE_CSS  :=  $(LOG_DIR)/analyze-css.json
CSS_STORED_LOG :=   $(LOG_DIR)/css-stored.log 
CSS_UPLOADED_LOG :=   $(LOG_DIR)/css-uploaded.log 


toBuildDir =   $(patsubst www/%,build/%,$(dir $1))  
toCollection  =  $(patsubst build/%,%,$(call toBuildDir,$1))  
toBuildFile =   $(patsubst www/%,build/%, $1)  
getMimeType = $(shell node -pe "\
 fs = require('fs');\
 re = /$1/;\
 n = require('cheerio').load(fs.readFileSync('$(EXIST_HOME)/mime-types.xml'),\
 { normalizeWhitespace: true, xmlMode: true});\
 n('extensions').filter(function(i, el){\
 return re.test(n(this).text());\
 }).parent().attr('name');\
")
#############################################################
styles: $(OUT_STYLES)

# $(ANALYZE-CSS)
styles-help:
	@echo styles help
	@echo $(call getMimeType,$(suffix t.atom))
# @echo STYLE_SRC_DIR: $(STYLE_SRC_DIR)
# @echo  $(ANALYZE_CSS)
# @echo $(STYLE_MAIN)
# @echo $(STYLE_STYLES)
# @echo $(STYLE_IMPORTS)
# @echo $(STYLE_OUT_DIR)
# @echo OUT_STYLES: $(OUT_STYLES)

# @echo $$(<$(EXIST_HOME)/mime-types.xml) | cheerio extensions.parent 

store-css: $(LOG_DIR)/css-stored.log 

upload-css: $(LOG_DIR)/css-upload.log 

analyze-css: $(LOG_DIR)/analyze-css.json

prior-metrics: $(LOG_DIR)/prior-analyze-css.json

phantomas: $(LOG_DIR)/phantomas.json

#@watch -q $(MAKE) styles
watch-styles:
	@watch -q  $(MAKE) styles

#	@watch -q $(MAKE) styles

.PHONY:  watch-styles prior-metrics

#############################################################
# $(OUT_STYLES): $(STYLE_MAIN) $(STYLE_IMPORTS)
# 	@mkdir -p $(@D)
# 	@echo  "MODIFY $@"
# 	@echo  "SRC  $< "
# 	@postcss --use postcss-import  $(<) 2> /dev/null > $@ && \
#  xq store-files-from-pattern \
#  '$(patsubst build/%,%,$(dir $@))'\
#  '$(dir $(abspath $@))'\
#  '$(notdir $@)'\
#  'text/css'  && \
#  curl -s --ipv4  http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')


$(LOG_DIR)/css-stored.log: $(STYLE_MAIN) $(STYLE_IMPORTS)
	@echo  "css-stored $@"
	@echo  "SRC  $< "  
	@touch $(STYLE_MAIN)
	@echo $(call toBuildDir,$<) 
	@echo $(call toCollection,$<)  
	@echo $(call getMimeType,$(suffix $(notdir $<))) 
	@postcss --use postcss-import  $(<) 2> /dev/null >  $(call toBuildFile,$<) 
	xq store-files-from-pattern \
 '$(call toCollection,$<)'\
 '$(abspath $(call toBuildDir,$<))'\
 '$(notdir $<)'\
 '$(call getMimeType,$(suffix $(notdir $<)))' 
	@curl -s --ipv4  http://localhost:35729/changed?files=$< 2> /dev/null >> $(LOG_DIR)/reload.log
	@echo $$(<$(TEMP_XML)) | cheerio mime-type\\:value
	@$(file >  $(LOG_DIR)/css-stored.log,\
 $(call toBuildFile,$<)\
 $(shell echo $$(<$(TEMP_XML)) | cheerio exist\\:value)\
 )

$(LOG_DIR)/css-uploaded.log: $(OUT_STYLES)
	@echo  "css-uploaded $@"
	@echo  "SRC  $< "

$(LOG_DIR)/analyze-css.json: $(OUT_STYLES)
	@echo  "analyze-css $@"
	@echo  "SRC  $< "
	@analyze-css --pretty --file $< > $@

$(LOG_DIR)/prior-analyze-css.json: $(LOG_DIR)/analyze-css.json
	@echo  "analyze-css"
	@node -pe "\
 R = require('./$(LOG_DIR)/analyze-css.json').metrics;" > $@

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

