define imageHelp
===============================================================================
SCRIPTS : working with scripts
 - js

Place in resources/scripts  folder 

    < src scripts
     [ optimise ] 
     [ build ]    scripts in  build.scripts dir
     [ upload ]   store into eXist dev server
     [ reload ]   TODO!  trigger live reload
     [ check ]     with prove run functional tests
=============================================================================

 Tools Used 

   
 Notes: path always relative to root

`make scripts`
`make watch-scripts`
`make scripts-help`

 1. scripts 
 2. watch-styles  ...  watch the directory
  'make scripts' will now be triggered by changes in dir
endef
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
SRC_SCRIPTS := $(shell find resources/scripts -name '*.js')
BUILD_SCRIPTS  := $(patsubst %,$(B)/%,$(SRC_SCRIPTS))
UPLOAD_SCRIPT_LOGS  := $(patsubst %.js,$(L)/%.log,$(SRC_SCRIPTS))

# BUILD_SCRIPTS := $(patsubst resources/scripts/%.js, $(L)/resources/scripts/%.json, $(SRC_SCRIPTS))
#############################################################
scripts: $(L)/upScripts.log

watch-scripts:
	@watch -q $(MAKE) scripts

.PHONY:  watch-scripts

#########################################################

$(B)/resources/scripts/%.js: resources/scripts/%.js
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo 'TODO! Lint ESLINT'
	@echo 'TODO! minify with closure compiler '
	@cp $< $@
	@echo '---------------------------------------------------'

$(L)/resources/scripts/%.log: $(B)/resources/scripts/%.js
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@echo "Uploaded eXist path: [ $$(cat $@) ]"

$(L)/upScripts.log: $(UPLOAD_SCRIPT_LOGS) 
	@$(MAKE) --silent $(UPLOAD_SCRIPT_LOGS) 
	@echo '' > $@ 
	@for log in $(UPLOAD_SCRIPT_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@clear
	@echo '--------------------------------'
	@echo '|  Uploaded Scripts Into eXist  |'
	@echo '--------------------------------'
	@cat $@
	@echo '----------------------------'
	@touch $(UPLOAD_SCRIPT_LOGS) 
# @echo '----------------------------'
# @echo '| Run Test With Prove       |'
# @echo '----------------------------'
# @touch $(UPLOAD_SCRIPT_LOGS) 
# @prove -v t/scripts.t

scripts-clean:
	@rm $(L)/upScripts.log

scripts-touch:
	@touch $(SRC_SCRIPTS)


# $(L)/resources/scripts/%.json: $(L)/resources/scripts/%.log
# @echo "## $@ ##"
# @echo "SRC: $<"
# @echo "STEM:  $*"
# @echo "input log: $<"
# @echo "input log last item: $(shell tail -n 1 $<)"
# @echo "output log: $@"
# @echo "suffix: $(suffix $(shell tail -n 1 $<)) "
# @curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
# @echo "output last livereload item: $(shell tail -n 1 $@  | jq -r  '.files[0]' | sed s%/db/%http://localhost:8080/exist/rest/% )"
# @echo '-----------------------------------------------------------------'

