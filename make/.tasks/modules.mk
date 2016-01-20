#==========================================================
#  XQUERY MODULES
#==========================================================
SRC_MODULES := $(shell find modules -name '*.xq*' )
MODULES_BUILD_DIR := $(BUILD_DIR)/modules
MODULES := $(patsubst modules/%, $(MODULES_BUILD_DIR)/%, $(SRC_MODULES))
MODULES_STORED_LOG   := $(LOG_DIR)/modules-stored.log
MODULES_RELOADED_LOG := $(LOG_DIR)/modules-reloaded.log 
MODULES_TESTED_LOG := $(LOG_DIR)/modules-tested.log 
#############################################################
modules: $(MODULES)  $(MODULES_STORED_LOG)  $(MODULES_RELOADED_LOG)

test-modules: $(MODULES_TESTED_LOG)

#for testing  use: make watch-modules
watch-modules:
	@watch -q $(MAKE) modules

.PHONY:  watch-modules

#############################################################

# Copy over xquery modules
$(MODULES_BUILD_DIR)/%: modules/%
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@xqlint $<
	@cp $< $@
	@echo '-----------------------------------------------------------------'

$(MODULES_STORED_LOG): $(MODULES_BUILT)
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

getModulesTestDir != if [ -e  $(MODULES_RELOADED_LOG) ] ; then\
 echo $$(< $(MODULES_RELOADED_LOG)) | jq -r '.files[0]' |\
 grep -oP '$(REPO)/\K.+(?=/(\w)+\.)'; fi  

$(MODULES_TESTED_LOG): $(MODULES_RELOADED_LOG)
	@echo "## $@ ##"
	@mkdir -p  t/$(getModulesTestDir)
	@echo -n "... look in '"
	@echo -n "t/$(getModulesTestDir)"  
	@echo "' for test plans"
	@$(if $(wildcard t/$(getModulesTestDir)/*.js),\
 casperjs test  $(wildcard t/$(getModulesTestDir)/*.js)  2>/dev/null,)
	@echo "prove ...."
	@echo "input log: $<"
	@echo "output log: $@"
	echo '-----------------------------------------------------------------'

