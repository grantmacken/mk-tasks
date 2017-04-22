
define modulesHelp
=========================================================
MODULES : working with eXist modules  - extension xq, xqm

    < src modules
     [ proccess ] compile check if the compile fails it will throw an error
     [ build ]    move modules into  build dir
     [ upload ]   store modules into eXist dev server
     [ test ]     run unit tests
     [ check ]    with prove run functional tests
==========================================================

`make modules`
`make watch-modules`
`make modules-help`

 1. modules 
 2. watch-modules  ...  watch the directory
  'make modules' will now be triggered by changes in dir
endef

modules-help: export modulesHelp:=$(modulesHelp)
modules-help:
	@echo "$${modulesHelp}"

SRC_XQM := $(shell find modules -name '*.xqm' )
SRC_XQ := $(shell find modules -name '*.xq' )
BUILD_XQM := $(patsubst modules/%,$(B)/modules/%,$(SRC_XQM))
BUILD_XQ := $(patsubst modules/%,$(B)/modules/%,$(SRC_XQ))
UPLOAD_MODULE_LOGS := $(patsubst %.xqm,$(L)/%.log,$(SRC_XQM)) $(patsubst %.xq,$(L)/%.log,$(SRC_XQ))

# $(info $(UPLOAD_MODULE_LOGS) )

modules: $(L)/upModules.log

watch-modules:
	@watch -q $(MAKE) modules

.PHONY:  watch-modules

#############################################################

$(B)/modules/%.xqm: modules/%.xqm
	@echo "##  $*  ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "src: [ $< ]"
	@xQcompile $< && echo "checked if exist can compile the module"
	@cp $< $@ && echo 'copied files into build directory'
	@echo '-----------------------------------------------------------------'

$(B)/modules/%.xq: modules/%.xq
	@echo "##  $*  ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "src: [ $< ]"
	@xQcompile $< && echo "checked if exist can compile the module"
	@cp $< $@ && echo 'copied files into build directory'
	@echo '-----------------------------------------------------------------'

$(L)/modules/%.log: $(B)/modules/%.xqm 
	@echo "## $@ ##" 
	@[ -d @D ] || mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@xQperm $< 'rwxr-xr-x'
	@echo "Uploaded eXist path: [ $$(cat $@) ]"

$(L)/modules/%.log: $(B)/modules/%.xq
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@echo "Uploaded eXist path: [ $$(cat $@) ]"


$(L)/upModules.log: $(UPLOAD_MODULE_LOGS)
	@$(MAKE) --silent $(UPLOAD_MODULE_LOGS)
	@echo '' > $@ 
	@for log in $(UPLOAD_MODULE_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@echo '----------------------------'
	@echo '|  Uploaded Module Into eXist  |'
	@echo '----------------------------'
	@cat $@
	@echo '----------------------------'
	@touch $(UPLOAD_MODULE_LOGS) 

modules-clean:
	@rm $(L)/upModules.log

modules-touch:
	@touch $(SRC_XQM)
	@touch $(SRC_XQ)
