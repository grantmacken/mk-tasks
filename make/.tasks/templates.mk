define templateHelp
=========================================================
TEMPLATES : working with eXist templates
 - extension html

  < src templates
  [ process ]  check well-formed, remove comments, decrease indents
  [ build ]    mv templates into build dir
  [ upload ]   store into eXist dev server
  [ reload ]   TODO!  trigger live reload
  [ check ]    with prove run functional tests
==========================================================

Tools Used: 
  - tidy for checking if well formed xml parse errors
  - tidy for removing comments and decrease indents 

`make templates`
`make watch-templates`
`make templates-help`

 1. templates 
 2. watch-templates  ...  watch the directory
  'make templates' will now be triggered by changes in dir
endef

templates-help: export templateHelp:=$(templateHelp)
templates-help:
	echo "$${templateHelp}"

SRC_TEMPLATES := $(shell find templates -name '*.html')
BUILD_TEMPLATES := $(patsubst %,$(B)/%,$(SRC_TEMPLATES))
UPLOAD_TEMPLATE_LOGS  := $(patsubst %.html,$(L)/%.log,$(SRC_TEMPLATES))

templates: $(L)/upTemplates.log

watch-templates:
	@watch -q $(MAKE) templates

.PHONY:  watch-templates

#############################################################

$(B)/templates/%.html: templates/%.html
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo 'Check with tidy xml parser: Warnings exit 1 and Errors exit 2 '
	@tidy -q -xml -utf8 -e  --show-warnings no $<
	@echo 'Use tidy to hide comments an indent space to 1'
	@tidy -q -xml -utf8 -i --indent-spaces 1 --hide-comments 1  --show-warnings no --output-file $@ $<
	@echo "Orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo " Build  size: [ $$(wc -c $@ | cut -d' ' -f1) ]"

$(L)/templates/%.log: $(B)/templates/%.html
	@echo "## $@ ##" 
	@[ -d @D ] || mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@echo "Uploaded eXist path: [ $$(cat $@) ]"

$(L)/upTemplates.log: $(UPLOAD_TEMPLATE_LOGS) 
	@$(MAKE) --silent $(UPLOAD_TEMPLATE_LOGS) 
	@echo '' > $@ 
	@for log in $(UPLOAD_TEMPLATE_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@echo '----------------------------'
	@echo '|  Uploaded Templates In eXist  |'
	@echo '----------------------------'
	@cat $@
	@echo '----------------------------'
	@touch $(UPLOAD_TEMPLATE_LOGS) 
# @echo '| Run Test With Prove       |'
# @echo '----------------------------'
# @touch $(UPLOAD_TEMPLATE_LOGS) 
# @prove -v t/templates.t
# @sleep 1 && clear

templates-clean:
	@rm $(L)/upTemplates.log

templates-touch:
	@touch $(SRC_TEMPLATES)

# $(L)/templates/%.json: $(L)/templates/%.log
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

# tmux send-keys -t $(ABBREV):2.2 "R" C-m
#
# @tidy -q  -utf8 --indent true --indent-spaces 2  \
#  --indent-attributes true --wrap 80 --hide-comments true \
#  --break-before-br true --sort-attributes alpha  --doctype omit -xml $<

