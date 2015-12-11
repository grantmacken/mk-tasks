#==========================================================
#  XHTML TEMPLATES
#==========================================================
SRC_TEMPLATES := $(shell find templates -name '*.html')
TEMPLATES_BUILD_DIR := $(BUILD_DIR)/templates
TEMPLATES_BUILT := $(patsubst templates/%, $(TEMPLATES_BUILD_DIR)/%, $(SRC_TEMPLATES))
TEMPLATES_STORED_LOG   := $(LOG_DIR)/templates-stored.log
TEMPLATES_RELOADED_LOG := $(LOG_DIR)/templates-reloaded.log 
TEMPLATES_TESTED_LOG := $(LOG_DIR)/templates-tested.log 

getModulesTestDir != [ -e  $(TEMPLATES_RELOADED_LOG) ] && \
 echo $$(< $(TEMPLATES_RELOADED_LOG) ) | jq -r '.files[0]' | \
 grep -oP '$(REPO)/\K.+(?=/(\w)+\.)'  

#############################################################
templates: $(TEMPLATES_BUILT)

watch-templates:
	@watch -q $(MAKE) templates

.PHONY:  watch-templates
#############################################################

$(TEMPLATES_BUILD_DIR)/%.html: templates/%.html
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@tidy -q  -utf8 --indent true --indent-spaces 2 \
 --indent-attributes true --wrap 80 --hide-comments true \
 --break-before-br true --sort-attributes alpha  --doctype omit $<
	@tidy -q -utf8 -xml -i $< > $@   
	@touch $<
	@echo '---------------------------------------------------'

$(MODULES_STORED_LOG): $(BUILD_HTML_TEMPLATES)
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC  $? "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join apps/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$?),,$?))"
	@echo "eXist store pattern: : $(subst build/,,$?) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $?)))"
	@echo "log-name: $(basename $(notdir $@))"
	@xq store-built-resource \
 '$(join apps/,$(REPO))' \
 '$(abspath  $(subst /$(subst build/,,$?),,$?))' \
 '$(subst build/,,$?)' '$(call getMimeType,$(suffix $(notdir $?)))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(MODULES_RELOADED_LOG): $(MODULES_STORED_LOG)
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo '-----------------------------------------------------------------'


$(MODULES_TESTED_LOG): $(MODULES_RELOADED_LOG)
	@echo "## $@ ##"
	@mkdir -p  t/$(getModulesTestDir)
	@echo -n "... look in '"
	@echo -n "t/$(getModulesTestDir)"  
	@echo "' for test plans"
ifneq ($(wildcard t/$(getModulesTestDir)/*.js),)
	@echo "prove ...."
	@casperjs test  $(wildcard t/$(getModulesTestDir)/*.js)  2>/dev/null
endif
	@echo "input log: $<"
	@echo "output log: $@"
	echo '-----------------------------------------------------------------'

