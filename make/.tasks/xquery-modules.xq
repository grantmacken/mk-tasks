#==========================================================
#  XQUERY MODULES
#  modules is the working directory for xquery modules
#  {project}/modules
#  in vim it is invoke on 'update'
#  Code, Compile, Test, Repeat
#
#  before copying to the build dir run thru compile test
# 1. xq compiled
#  if the compile fails it will throw an error
#
# - when a file is copied to the build dirs 
# - add file to built log 
# - then invoke reload modules
#
# 1. Store xQuery file into eXist-db local development server and log eXist response
# 2. Let livereload server know we have changed files and log tiny-lr server response
# 3. Tap test with Prove Run any tests in test dir 
#
#
# #==========================================================

SOURCE_MODULES := $(shell find modules -name '*.xqm' )
BUILD_MODULES  := $(patsubst modules/%,$(B)/modules/%,$(SOURCE_MODULES))

SRC_XQ := $(shell find modules -name '*.xq' )
SRC_XQM := $(shell find modules -name '*.xqm' )
SRC_XQL := $(shell find modules -name '*.xql' )

SRC_API := $(shell find modules/api -name '*.xqm' )
SRC_LIB := $(shell find modules/lib -name '*.xqm' )
SRC_RENDER := $(shell find modules/render -name '*.xqm' )

XQ_MODULES  := $(patsubst modules/%.xq,$(L)/modules/%.json,$(SRC_XQ))
API_MODULES := $(patsubst modules/%.xqm,$(L)/modules/%.json,$(SRC_API))
LIB_MODULES := $(patsubst modules/%.xqm,$(L)/modules/%.json,$(SRC_LIB))
RENDER_MODULES := $(patsubst modules/%.xqm,$(L)/modules/%.json,$(SRC_RENDER))

# $(info $(LIB_MODULES))
# $(info $(RENDER_MODULES))
# secondaries := $(patsubst modules/%.xqm,$(B)/modules/%.json,$(SRC_XQ))

# .SECONDARY: $(secondaries)


# $(info $(SRC_T_MODULES))
# $(info $(TEST_LIBS))
# $(info $(TEST_SUITE))
# $(info $(XQM_TEST_MODULES))
#############################################################

render-modules: $(RENDER_MODULES)
lib-modules:    $(LIB_MODULES)
api-modules:    $(API_MODULES)

modules: $(BUILD_MODULES)

#$(LIB_MODULES) $(API_MODULES) $(RENDER_MODULES)
 
#for testing  use: make watch-modules
watch-modules:
	@watch -q $(MAKE) modules

.PHONY:  watch-modules 

#############################################################
# @$(if $(findstring api/,$*),\
# xQ register '$<'  && \
# echo 'registered api module', )
# Copy over xqm query modules into build

$(B)/modules/%: modules/%
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "STEM: [ $* ]"
	@xQ compile $< && echo "checked if eXist can compile the module"
	@xQ store $< && echo "stored module into eXist" 
	@$(if $(shell xQ permissions $< | grep 'rwxrwxr-x'),,\
 xQ chmod '$<' 'rwxrwxr-x' && \
 echo 'set execute perimissions for xquery modules')
	@xQ register 'modules/api/router.xqm' && echo 'registered api module'
	@cp $< $@ && echo 'copied files into build directory'
	@echo '-----------------------------------------------------------------'

# Copy over xq xquery modules into build
# Copy over xq xquery modules into build

# $(B)/modules/%.xq: modules/%.xq
# @echo "## $@ ##"
# @mkdir -p $(@D)
# @echo "SRC: $<" >/dev/null
# @echo "before we copy into the build dir" >/dev/null
# @echo "check if eXist can compile the module" >/dev/null
# @echo 'copied files into build directory' >/dev/null
# xq compile $<
# @cp $< $@
# @echo '-----------------------------------------------------------------'

# Store in eXist and log response

$(L)/modules/%.log: $(B)/modules/%.xqm
	@echo "## $@ ##"
	@echo "SRC: $<" >/dev/null
	@echo "eXist collection_uri: $(join apps/,$(NAME))" >/dev/null
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(<)),,$(<)))" >/dev/null
	@echo "eXist store pattern: : $(subst build/,,$(<)) " >/dev/null
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(<))))" >/dev/null
	@echo "stored log path : $(basename $(subst build/,,$(<)))" >/dev/null
	@echo "stored log dir : $(L)/$(dir $(subst build/,,$(<)))" >/dev/null
	@echo "dir : $(shell cut -d '/' -f1 <<< '$*') " >/dev/null
	@mkdir -p $(L)/$(dir $(subst build/,,$(<)))
	@xQ store-built-resource \
 '$(join apps/,$(NAME))' \
 '$(abspath  $(subst /$(subst build/,,$(<)),,$(<)))' \
 '$(subst build/,,$(<))' \
 '$(call getMimeType,$(suffix $(notdir $(<))))' \
 '$(basename $(subst build/,,$(<)))'
	@echo "make sure we have correct execute permisions for modules"
	@$(if $(shell xQ permissions $(subst build/,,$(<)) | grep 'rwxrwxr-x'),,\
 xQ chmod '$(subst build/,,$(<))' 'rwxrwxr-x')
	@echo '-----------------------------------------------------------------'

# Store in eXist and log response

$(L)/modules/%.log: $(B)/modules/%.xq
	@echo "## $@ ##"
	@echo "SRC: $<" >/dev/null
	@echo "eXist collection_uri: $(join apps/,$(NAME))" >/dev/null
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(<)),,$(<)))"   >/dev/null
	@echo "eXist store pattern: : $(subst build/,,$(<)) " >/dev/null
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(<))))" >/dev/null
	@echo "stored log path : $(basename $(subst build/,,$(<)))" >/dev/null
	@echo "stored log dir : $(L)/$(dir $(subst build/,,$(<)))" >/dev/null
	@mkdir -p $(L)/$(dir $(subst build/,,$(<)))
	@xQ store-built-resource \
 '$(join apps/,$(NAME))' \
 '$(abspath  $(subst /$(subst build/,,$(<)),,$(<)))' \
 '$(subst build/,,$(<))' \
 '$(call getMimeType,$(suffix $(notdir $(<))))' \
 '$(basename $(subst build/,,$(<)))'
	@echo "make sure we have correct execute permisions for modules"
	@$(if $(shell xq permissions $(subst build/,,$(<)) | grep 'rwxrwxr-x'),,\
 xq chmod '$(subst build/,,$(<))' 'rwxrwxr-x')
	@echo '-----------------------------------------------------------------'

#  After we have stored xquery file into db
#  We will
# 1: If a restxq module in api folder
#    then register module
# 2: If the module has a tap test plan located in t dir
#    then 
#      if api restxq module (module/api) then prove 
#    else
#      if lib ( modules/lib/{}.xqm  | modules/tests/lib/{}.xqm )
#         then these have one test plan t/modules/lib/{}.t for both
# 3: Notify LiveReload server and log lr response

testPath = $(subst /tests/,/,$(addprefix t/modules/, $(addsuffix .t,$1)))
hasTest = $(wildcard $(call testPath,$1))
isRestxqReg = $(shell echo '$1')
relDbPath = $(shell tail -n 1 $1 | grep -oP '$(NAME)/\K(.+)')

$(L)/modules/%.json: $(L)/modules/%.log
	@echo "## $@ ##"
	@echo "SRC: $<" >/dev/null
	@echo "STEM:  $*"
	@echo "not dir: $(notdir $*)"
	@echo "dir: $(dir $*)"
	@echo "input log: $<" >/dev/null
	@echo "input log last item: $(shell tail -n 1 $<)" >/dev/null
	@echo "output log: $@" >/dev/null
	@echo "suffix: $(suffix $(shell tail -n 1 $<)) " >/dev/null
	@echo "stored-module-path: $(call relDbPath,$<)"
	@echo "reregister restxq modules TODO!"
	@xq register 'modules/api/router.xqm' >/dev/null
	@echo "check if possible test plan: $(call testPath,$*)"
	@$(if $(call hasTest,$*),\
 xq prove $(call relDbPath,$<),)
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo "output last livereload item: $(shell tail -n 1 $@  | jq -r  '.files[0]' | sed s%/db/%http://localhost:8080/exist/rest/% )"
	@echo '-----------------------------------------------------------------'

# tmuxSendKeys != tmux send-keys -t $(ABBREV):1.3 "R" C-m
# $(if $(call isRestxqApi,$*),prove -v $(call testPath,$*), xq prove $(call relDbPath,$<))\
# xq prove $(shell tail -n 1 $< | grep -oP '$(NAME)/\K(.+)')),\
# @$(if $(wildcard $(subst /tests/,/,$(addprefix t/modules/, $(addsuffix .t,$*)))),\
# $(if $(shell echo '$(dir $*)' | grep -oP '^api' ),\
# echo 'restxq module ... prove using curl' &&\
# echo '$(subst /tests/,/,$(addprefix t/modules/, $(addsuffix .t,$*)))',\
# echo 'lib module ... xq prove tap output from xqsuite' ,\
# ) )
