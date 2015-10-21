#==========================================================
#  XHTML MODULES
#==========================================================
SRC_TEMPLATES := $(shell find templates -name '*.html')
TEMPLATES_BUILD_DIR := $(BUILD_DIR)/templates
BUILD_HTML_TEMPLATES := $(patsubst templates/%, $(TEMPLATES_BUILD_DIR)/%, $(SRC_TEMPLATES))
#############################################################
templates: $(BUILD_HTML_TEMPLATES)

#for testing  use: make watch-templates
watch-templates:
	@watch -q $(MAKE) templates

.PHONY:  watch-templates
#############################################################

# Copy over templates
$(TEMPLATES_BUILD_DIR)/%.html: templates/%.html
	@mkdir -p $(@D)
	@echo "PARAM 1 (route) :$(dir $<)"
	@echo "PARAM 2 (directory): $(dir $(abspath $@))"
	@echo "PARAM 3 (file) :$(notdir $@)"
	@cp $< $@
	xq store-files-from-pattern \
 '$(patsubst build/%,%,$(dir $@))' \
 '$(dir $(abspath $@))' '$(notdir $@)' \
 'application/xml'  && \
 curl \
 -s \
 --ipv4 \
 http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')
