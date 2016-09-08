
#==========================================================
#  WWW STATIC ASSETS
#==========================================================
# path relative to root
SRC_SCRIPTS := $(shell find resources/scripts -name '*.js')

SCRIPTS := $(patsubst resources/scripts/%.js, $(L)/resources/scripts/%.json, $(SRC_SCRIPTS))
#############################################################
scripts: $(SCRIPTS)

#for testing  use: make watch-templates
watch-scripts:
	@watch -q $(MAKE) scripts

.PHONY:  watch-scripts



#########################################################

$(B)/resources/scripts/%: resources/scripts/%
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@cp $< $@
	@echo '---------------------------------------------------'

#########################################################

$(L)/resources/scripts/%.log: $(B)/resources/scripts/%.js
	@echo "## $@ ##" 
	@echo "SRC: $<"
	@echo "eXist collection_uri: $(join apps/,$(NAME))" 
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(<)),,$(<)))"
	@echo "eXist store pattern: : $(subst build/,,$(<)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(<))))"
	@echo "stored log path : $(basename $(subst build/,,$(<)))"
	@echo "stored log dir : $(L)/$(dir $(subst build/,,$(<)))"
	@echo "dir : $(shell cut -d '/' -f1 <<< '$*') "
	@mkdir -p $(L)/$(dir $(subst build/,,$(<)))
	@xq store-built-resource \
 '$(join apps/,$(NAME))' \
 '$(abspath  $(subst /$(subst build/,,$(<)),,$(<)))' \
 '$(subst build/,,$(<))' \
 '$(call getMimeType,$(suffix $(notdir $(<))))' \
 '$(basename $(subst build/,,$(<)))'
	@echo '-----------------------------------------------------------------'


$(L)/resources/scripts/%.json: $(L)/resources/scripts/%.log
	@echo "## $@ ##"
	@echo "SRC: $<"
	@echo "STEM:  $*"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@echo "suffix: $(suffix $(shell tail -n 1 $<)) "
	@curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
	@echo "output last livereload item: $(shell tail -n 1 $@  | jq -r  '.files[0]' | sed s%/db/%http://localhost:8080/exist/rest/% )"
	@echo '-----------------------------------------------------------------'

