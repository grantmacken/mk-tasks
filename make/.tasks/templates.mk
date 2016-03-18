#==========================================================
#  XHTML TEMPLATES
#==========================================================
SRC_TEMPLATES := $(shell find templates -name '*.html')
TEMPLATES_BUILD_DIR := $(BUILD_DIR)/templates
TEMPLATES := $(patsubst templates/%, $(TEMPLATES_BUILD_DIR)/%, $(SRC_TEMPLATES))
TEMPLATES_BUILT_LOG   := $(LOG_DIR)/templates-built.log
TEMPLATES_STORED_LOG   := $(LOG_DIR)/templates-stored.log
TEMPLATES_RELOADED_LOG := $(LOG_DIR)/templates-reloaded.log
TEMPLATES_TESTED_LOG := $(LOG_DIR)/templates-tested.log

loggedTemplateBuiltFile != [ -e  $(TEMPLATES_BUILT_LOG) ] && \
 tail -n 1 $(TEMPLATES_BUILT_LOG)

getTemplatesTestDir != [ -e  $(TEMPLATES_RELOADED_LOG) ] && \
 echo $$(< $(TEMPLATES_RELOADED_LOG) ) | jq -r '.files[0]' | \
 grep -oP '$(REPO)/\K.+(?=/(\w)+\.)'

#############################################################
templates: $(TEMPLATES)

reload-templates: $(TEMPLATES_STORED_LOG) $(TEMPLATES_RELOADED_LOG)
 #  $(TEMPLATES_STORED_LOG)  $(TEMPLATES_RELOADED_LOG) 
watch-templates:
	@watch -q $(MAKE) templates

# tidy -q --doctype omit --accessibility-check 1 --show-errors 6 --show-info 1 --show-warnings 1 --gnu-emacs 1 $<
.PHONY:  watch-templates
#############################################################

$(TEMPLATES_BUILD_DIR)/%.html: templates/%.html
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@tidy -q  -utf8 --indent true --indent-spaces 2 \
 --indent-attributes true --wrap 80 --hide-comments true \
 --break-before-br true --sort-attributes alpha  --doctype omit -xml $<
	@tidy -q -utf8 -xml --indent true --indent-spaces 2 --hide-comments true $< > $@
	@$(file > $(TEMPLATES_BUILT_LOG),$@)
	@$(MAKE) reload-templates
	@echo '---------------------------------------------------'

$(TEMPLATES_STORED_LOG): $(TEMPLATES_BUILT_LOG)   
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC $(loggedTemplateBuiltFile) "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join apps/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(loggedTemplateBuiltFile)),,$(loggedTemplateBuiltFile)))"
	@echo "eXist store pattern: : $(subst build/,,$(loggedTemplateBuiltFile)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(loggedTemplateBuiltFile))))"
	@echo "log-name: $(basename $(notdir $@))" 
	@xq store-built-resource \
 '$(join apps/,$(REPO))' \
 '$(abspath  $(subst /$(subst build/,,$(loggedTemplateBuiltFile)),,$(loggedTemplateBuiltFile)))' \
 '$(subst build/,,$(loggedTemplateBuiltFile))' '$(call getMimeType,$(suffix $(notdir $(loggedTemplateBuiltFile))))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(TEMPLATES_RELOADED_LOG): $(TEMPLATES_STORED_LOG)
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo '-----------------------------------------------------------------'

$(TEMPLATES_TESTED_LOG): $(TEMPLATES_RELOADED_LOG)
	@echo "## $@ ##"
	@mkdir -p  t/$(getTemplatesTestDir)
	@echo -n "... look in '"
	@echo -n "t/$(getTemplatesTestDir)"
	@echo "' for test plans"
ifneq ($(wildcard t/$(getTemplatesTestDir)/*.js),)
	@echo "prove ...."
	@casperjs test  $(wildcard t/$(getTemplatesTestDir)/*.js)  2>/dev/null
endif
	@echo "input log: $<"
	@echo "output log: $@"
	echo '-----------------------------------------------------------------'

