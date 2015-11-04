#==========================================================
#  XHTML TEMPLATES
#==========================================================
SRC_TEMPLATES := $(shell find templates -name '*.html')
TEMPLATES_BUILD_DIR := $(BUILD_DIR)/templates
BUILD_HTML_TEMPLATES := $(patsubst templates/%, $(TEMPLATES_BUILD_DIR)/%, $(SRC_TEMPLATES))
#############################################################
templates: $(BUILD_HTML_TEMPLATES)

watch-templates:
	@watch -q $(MAKE) templates

.PHONY:  watch-templates
#############################################################

$(TEMPLATES_BUILD_DIR)/%.html: templates/%.html
	@mkdir -p $(@D)
	@echo "PARAM 1 (route) :$(dir $<)"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file) :$(notdir $@)"
	@cp $< $@
	xq store-files-from-pattern \
 '$(dir $<)'\
 '$(abspath $(dir $(addprefix build/,$<)))'\
 '$(notdir $<)'\
 '$(call getMimeType,$(suffix $(notdir $<)))' 
	@curl -s --ipv4  http://localhost:35729/changed?files=$< 2> /dev/null >> $(LOG_DIR)/reload.log
	@echo $$(<$(TEMP_XML)) | cheerio mime-type\\:value
	@$(file >  $(LOG_DIR)/template-stored.log,\
 $(addprefix build/,$<)\
 $(shell echo $$(<$(TEMP_XML)) | cheerio exist\\:value)\
 )
# xq store-files-from-pattern \
#  '$(patsubst build/%,%,$(dir $@))' \
#  '$(dir $(abspath $@))' '$(notdir $@)' \
#  'application/xml'  && \
#  curl \
#  -s \
#  --ipv4 \
#  http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')
