define iconHelp
===============================================================================
 ICONS is the working directory for svg icons
 Since we are using HTTP/2 which muliplexes requests we will not create sprites 
each icon in resourse icons id optimised delivered to build dir, then uploaded 
to eXist
    < src icons 
     [ xmllint ]  check if well formed   
     [ optimise ] use scour to convert to svgz and output to 
     [ build ]    icons in  build.icons dir
     [ upload ]   store into eXist dev server
     [ reload ]   TODO!  trigger live reload
     [ check ]    with prove run functional tests
=============================================================================

   https://github.com/scour-project/scour
 
 Notes: path always relative to root

`make icons`
`make watch-icons`
`make icons-help`

 1. icons 
 2. watch-styles  ...  watch the directory
  'make icons' will now be triggered by changes in dir
endef

icons-help: export iconHelp:=$(iconHelp)
icons-help:
	echo "$${iconHelp}"

SOURCE_ICONS := $(shell find resources/icons -name '*.svg')
BUILD_ICONS  := $(patsubst %,$(B)/%,$(SOURCE_ICONS))
BUILD_ZIPPED_ICONS  := $(patsubst %,$(B)/%z,$(SOURCE_ICONS))
UPLOAD_ICON_LOGS  := $(patsubst %.svg,$(L)/%.log,$(SOURCE_ICONS))
#
# $(BUILD_ICONS) $(BUILD_ZIPPED_ICONS)

icons: $(L)/upIcons.log

#@watch -q $(MAKE) icons
watch-icons:
	@watch -q $(MAKE) icons

.PHONY:  watch-icon

$(B)/resources/icons/%.svgz: resources/icons/%.svg
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "STEM: [ $* ]"
	@echo 'use xmllint check if SVG document well formed'
	xmllint --noout $<
	@echo 'use scour to optimise and create zipped file'
	@scour -i $< -o $@ --enable-viewboxing --enable-id-stripping \
 --enable-comment-stripping --shorten-ids --indent=none >/dev/null

$(B)/resources/icons/%.svg: resources/icons/%.svg
	@echo "## $@ ##"
	@[ -d @D ] || mkdir -p $(@D)
	@echo "SRC: [ $< ]"
	@echo "STEM: [ $* ]"
	@echo 'use xmllint check if SVG document well formed'
	xmllint --noout $<
	@echo 'use scour to optimise and create zipped file'
	@scour -i $< -o $@ --enable-viewboxing --enable-id-stripping \
 --enable-comment-stripping --shorten-ids --indent=none >/dev/null

$(L)/resources/icons/%.log: $(B)/resources/icons/%.svgz
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo "SRC: [ $< ]"  >/dev/null
	@echo "STEM: [ $* ]" >/dev/null
	@echo 'upload to eXist'
	@xQstore $< > $@
	@cat $@

$(L)/upIcons.log: $(UPLOAD_ICON_LOGS) 
	@$(MAKE) --silent $(UPLOAD_ICON_LOGS) 
	@echo '' > $@ 
	@for log in $(UPLOAD_ICON_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@sleep 1 && clear
	@echo '----------------------------'
	@echo '|  Uploaded Icons In eXist  |'
	@echo '----------------------------'
	@cat $@
	@echo '----------------------------'
	@sleep 1
	@echo '----------------------------'
	@echo '| Run Test With Prove       |'
	@echo '----------------------------'
	@touch $(UPLOAD_ICON_LOGS) 
	@prove -v t/icons.t
	@sleep 1
	@echo '-----------------------------'
	@echo '| Dump View With W3M browser |'
	@echo '-----------------------------'
	@w3m -dump $(WEBSITE)/icons/mail
	@echo '-----------------------------'

icons-clean:
	@rm $(L)/upIcons.log

icons-touch:
	@touch $(SOURCE_ICONS)

# icons-reloaded: 
# @echo "## $@ ##"
# @echo "Let livereload server know we have changed files"
# @echo "input log: $<"
# @echo "input log last item: $(shell tail -n 1 $<)"
# @echo "output log: $@"
# @curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
# @echo '-----------------------------------------------------------------'

# xmllint --noout $<
# @java -cp $(SAXON) \
 # net.sf.saxon.Query \
 # \\!method=text \
 # -qversion:3.0 \
 # -qs:"doc('file://$(abspath $<)')"

# @tidy -q  -utf8 --indent true --indent-spaces 2  \
# --indent-attributes true --wrap 80 --hide-comments true \
# --break-before-br true --sort-attributes alpha  --doctype omit -xml $<
# $(B)/resources/icons/icons.svg:  $(ICON_IMPORTS)
# @echo "## $@ ##"
# @mkdir -p $(dir $@)
# @echo $@
# @echo "SRC  $< "
# @echo "collection_uri: $(dir $<)"
# @echo "directory: $(abspath $(dir $(addprefix build/,$<)))"
# @echo "pattern: $(notdir $<)"
# @echo "mime-type: $(call getMimeType,$(suffix $(notdir $<)))"
# @echo '<svg xmlns="http://www.w3.org/2000/svg" style="display: none;">' \
# > .temp/temp.xml
# @cat $(ICON_IMPORTS) | sed -e 's% xmlns="http://www.w3.org/2000.svg"%%g' \
# | sed -e 's%<svg%<symbol%g' \
# | sed -e 's%</svg%</symbol%g' \
# | sed -e 's%</svg%</symbol%g' \
# | sed -e 's% fill="currentcolor"%%g' \
# >> .temp/temp.xml
# @echo '</svg>'  >> .temp/temp.xml
# @node -pe "\
# fs = require('fs');\
# var n = require('cheerio').load( fs.readFileSync('.temp/temp.xml', 'utf-8')  ,{normalizeWhitespace: false,xmlMode: true});\
# ;n.xml()" > $@ 



