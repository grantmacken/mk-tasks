#==========================================================
#  XHTML TEMPLATES
# 
#  eXist HTML templates
#   
#  {project}/templates
#
#==========================================================
SRC_TEMPLATES := $(shell find templates -name '*.html')
TEMPLATES := $(patsubst templates/%.html, $(L)/templates/%.json, $(SRC_TEMPLATES))
#############################################################
templates: $(TEMPLATES)

# $(info $(TEMPLATES))

reload-templates: $(TEMPLATES_STORED_LOG) $(TEMPLATES_RELOADED_LOG)
 #  $(TEMPLATES_STORED_LOG)  $(TEMPLATES_RELOADED_LOG) 
watch-templates:
	@watch -q $(MAKE) templates

# tidy -q --doctype omit --accessibility-check 1 --show-errors 6 --show-info 1 --show-warnings 1 --gnu-emacs 1 $<
.PHONY:  watch-templates
#############################################################

$(B)/templates/%.html: templates/%.html
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@cp $< $@
	@echo '---------------------------------------------------'

# Store in eXist and log response

$(L)/templates/%.log: $(B)/templates/%.html
	@echo "## $@ ##" 
	@echo "SRC: $<"
	@echo "eXist collection_uri: $(join apps/,$(NAME))" 
	@echo "directory in file system: $(abspath  $(subst /$(subst build/,,$(<)),,$(<)))" 
	@echo "eXist store pattern: : $(subst build/,,$(<)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(<))))"
	@echo "stored log path : $(basename $(subst build/,,$(<)))"
	@echo "stored log dir : $(L)/$(dir $(subst build/,-,$(<)))"
	@echo "dir : $(shell cut -d '/' -f1 <<< '$*') "
	@mkdir -p $(L)/$(dir $(subst build/,,$(<)))
	@xq store-built-resource \
 '$(join apps/,$(NAME))' \
 '$(abspath  $(subst /$(subst build/,,$(<)),,$(<)))' \
 '$(subst build/,,$(<))' \
 '$(call getMimeType,$(suffix $(notdir $(<))))' \
 '$(basename $(subst build/,,$(<)))'
	@echo "make sure we have correct permisions for templates"
	@$(if $(shell xq permissions $(subst build/,,$(<)) | grep 'rwxrwxr-x'),,\
 xq chmod '$(subst build/,,$(<))' 'rwxrwxr-x')
	@echo '-----------------------------------------------------------------'

$(L)/templates/%.json: $(L)/templates/%.log
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

# tmux send-keys -t $(ABBREV):2.2 "R" C-m
#
# @tidy -q  -utf8 --indent true --indent-spaces 2  \
#  --indent-attributes true --wrap 80 --hide-comments true \
#  --break-before-br true --sort-attributes alpha  --doctype omit -xml $<

