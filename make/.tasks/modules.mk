#==========================================================
#  XQUERY MODULES
#  modules is the working directory for xquery modules
#   before copying to the build dir run thru linters
# 1. xq compile
#
# - when a file is copied to the build dirs 
# - add file to built log 
# - then invoke reload modules
#
# 1. Store xQuery file into eXist-db local development server and log eXist response
# 2. Let livereload server know we have changed files and log tiny-lr server response
# 3. Tap test with Prove Run any tests in test dir 
#    Lint 
#
# #==========================================================
SRC_MODULES := $(shell find modules -name '*.xq*' )
MODULES_BUILD_DIR := $(B)/modules
MODULES := $(patsubst modules/%, $(B)/modules/%, $(SRC_MODULES))
MODULES_BUILT_LOG   := $(L)/modules-built.log
MODULES_STORED_LOG   := $(L)/modules-stored.log
MODULES_RELOADED_LOG := $(L)/modules-reloaded.log 
MODULES_TESTED_LOG := $(L)/modules-tested.log 
#############################################################

loggedModuleBuiltFile != [ -e  $(L)/modules-built.log ] && \
 tail -1 $(L)/modules-built.log

xqCompile = $(shell xq compile '$(abspath $1)')

# getModulesTestDir != if [ -e  $(MODULES_RELOADED_LOG) ] ; then\
#  echo $$(< $(MODULES_RELOADED_LOG)) | jq -r '.files[0]' |\
#  grep -oP '$(REPO)/\K.+(?=/(\w)+\.)'; fi

modules: $(MODULES)

reload-modules: $(L)/modules-reloaded.log

# test-modules: $(MODULES_TESTED_LOG)

#for testing  use: make watch-modules
watch-modules:
	@watch -q $(MAKE) modules

.PHONY:  watch-modules

#############################################################

# Copy over xquery modules
# 
#  @xqlint $<  
# before 
#

$(B)/modules/%: modules/%
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@$(if $(call xqCompile ,$<),\
 $(shell echo  '$(abspath $<)$(call xqCompile ,$<) ' >&2 ; false) ,\
 $(info lint - $< : OK ))
	@cp $< $@
	@echo 'copied files into build directory'
	@echo 'add file to built log then invoke reload modules'
	@$(file > $(L)/modules-built.log,$@)
	@$(MAKE) reload-modules
	@echo '-----------------------------------------------------------------'

$(L)/modules-stored.log: $(L)/modules-built.log
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC $(loggedModuleBuiltFile) "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join apps/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(loggedModuleBuiltFile)),,$(loggedModuleBuiltFile)))"
	@echo "eXist store pattern: : $(subst build/,,$(loggedModuleBuiltFile)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(loggedModuleBuiltFile))))"
	@echo "log-name: $(basename $(notdir $@))" 
	@xq store-built-resource \
 '$(join apps/,$(REPO))' \
 '$(abspath  $(subst /$(subst build/,,$(loggedModuleBuiltFile)),,$(loggedModuleBuiltFile)))' \
 '$(subst build/,,$(loggedModuleBuiltFile))' '$(call getMimeType,$(suffix $(notdir $(loggedModuleBuiltFile))))' \
 '$(basename $(notdir $@))'
	@echo '-----------------------------------------------------------------'

$(L)/modules-reloaded.log: $(L)/modules-stored.log
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo '-----------------------------------------------------------------'


# $(L)/modules-tested.log: $(L)/modules-reloaded.log
# @echo "## $@ ##"
# @mkdir -p  t/$(getModulesTestDir)
# @echo -n "... look in '"
# @echo -n "t/$(getModulesTestDir)"  
# @echo "' for test plans"
# @$(if $(wildcard t/$(getModulesTestDir)/*.js),\
# casperjs test  $(wildcard t/$(getModulesTestDir)/*.js)  2>/dev/null,)
# @echo "prove ...."
# @echo "input log: $<"
# @echo "output log: $@"
# echo '-----------------------------------------------------------------'

