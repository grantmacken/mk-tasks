define stylesHelp
===============================================================================
STYLES : working with styles
 - css
 Workin folder: 'resources/styles'

< src styles
[ postproccess ] postcss - autoprefixer, cssnano (minify, remove comments etc)
[ build ] zopfli gzipped css files into build dir
[ upload ] store into eXist dev server
[ reload ] TODO!  trigger live reload
[ check ]  with prove run functional tests
- use Curl to check if serving gzipped file via gzip-static nginx declaration
- use Curl check if serving unzipped file via gunzip nginx declaration

=============================================================================

Tools Used:
[zopfli](https://github.com/google/zopfli) :              to gzip 
[postcss-cli](https://github.com/pirxpilot/postcss-cli):  to run
 - [autoprefixer](https://github.com/postcss/autoprefixer)
 - [cssnano](http://cssnano.co/optimisations)
 - and maybe some other stuff

`make styles`
`make watch-styles`
`make styles-help`

 1. styles 
 2. watch-styles  ...  watch the directory
  'make styles' will now be triggered by changes in dir
endef

styles-help: export stylesHelp:=$(stylesHelp)
styles-help:
	echo "$${stylesHelp}"

SRC_STYLES := $(shell find resources/styles -name '*.css')
BUILD_STYLES  := $(patsubst %.css,$(B)/%.css.gz,$(SRC_STYLES))
UPLOAD_STYLE_LOGS  := $(patsubst %.css,$(L)/%.log,$(SRC_STYLES))

styles: $(L)/upStyles.log

watch-styles:
	@watch -q $(MAKE) $(UPLOAD_STYLE_LOGS)

.PHONY:  watch-styles

$(B)/resources/styles/%.css.gz: resources/styles/%.css
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@mkdir -p $(T)/resources/styles
	@echo "CSS file: [ $* ]"
	@postcss \
 --use autoprefixer --autoprefixer.browsers "> 5%"\
 --use cssnano\
 --output $(T)/resources/styles/$*.css $< &&  echo 'shrinked with cssnano' || false
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "cssnano size: [ $$(wc -c $(T)/resources/styles/$*.css | cut -d' ' -f1) ]"
	@zopfli $(T)/resources/styles/$*.css &&  echo 'gziped with zopfli' || false
	@[ -e $(T)/resources/styles/$(*).css ] && rm $(T)/resources/styles/$(*).css
	@mv $(T)/resources/styles/$*.css.gz $@
	@echo "gzip bld size: [ $$(wc -c $@ | cut -d' ' -f1) ]"
	@echo '---------------------------------------------------'

$(L)/resources/styles/%.log: $(B)/resources/styles/%.css.gz
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo 'Upload $(basename $@) to eXist'
	@xQstore $< > $@
	@echo "Uploaded eXist path: [ $$(cat $@) ]"

$(L)/upStyles.log: $(UPLOAD_STYLE_LOGS) 
	@$(MAKE) --silent $(UPLOAD_STYLE_LOGS) 
	@echo '' > $@ 
	@for log in $(UPLOAD_STYLE_LOGS); do \
 cat $$log >> $@ ; \
 done
	@echo "$$( sort $@ | uniq )" > $@
	@echo '--------------------------------'
	@echo '| Styles Uploaded Into eXistdb  |'
	@echo '--------------------------------'
	@cat $@
	@echo '----------------------------'
	@touch $(UPLOAD_STYLE_LOGS) 
	@echo '----------------------------'
	@echo '| Run Test With Prove       |'
	@echo '----------------------------'
	@prove -v t/styles.t

styles-clean:
	@[ -e $(L)/upStyles.log ] && rm $(L)/upStyles.log
	@rm $(BUILD_STYLES)
# @rm $(UPLOAD_STYLE_LOGS)

styles-touch:
	@touch $(SRC_STYLES)
#==========================================================
#   STATIC ASSET PIPELINE for styles
#==========================================================

# analyze-css: $(LOG_DIR)/analyze-css.json

# prior-metrics: $(LOG_DIR)/prior-analyze-css.json

# phantomas: $(LOG_DIR)/phantomas.json

# #@watch -q $(MAKE) styles
# watch-styles:
#@watch --interval 1 -q $(MAKE) styles

# #@watch -q $(MAKE) styles

# .PHONY:  watch-styles test-styles

# test-styles:
#@phantomas $(WEBSITE) --verbose --stop-at-onload --no-externals --colors --timeout=30 --config=$(PHANTOMAS_CONFIG) --reporter=tap

# $(L)/styles-reloaded.log: $(L)/styles-stored.log
# <@echo "## $@ ##"
# @echo "Let livereload server know we have changed files"
# @echo "input log: $<"
# @echo "input log last item: $(shell tail -n 1 $<)"
# @echo "output log: $@"
# @curl -s --ipv4  http://localhost:35729/changed?files=$(shell tail -n 1 $<) > $@
# @echo '-----------------------------------------------------------------'

# $(L)/styles-tested.log: $(L)/styles-reloaded.log
# @echo "## $@ ##"
# @echo "prove with phantomas"
# @echo "input log: $<"
# @echo "$(WEBSITE)"
# @echo "output log: $@"
# @phantomas $(WEBSITE) --stop-at-onload --reporter json > $@
# @echo '-----------------------------------------------------------------'

# <$(LOG_DIR)/css-uploaded.log: $(OUT_STYLES)
# @echo  "css-uploaded $@"
# @echo  "SRC  $< "

# $(LOG_DIR)/analyze-css.json: $(OUT_STYLES)
# @echo  "analyze-css $@"
# @echo  "SRC  $< "
# @analyze-css --pretty --file $< > $@
# @echo "$$(<$@)"

# $(LOG_DIR)/prior-analyze-css.json: $(LOG_DIR)/analyze-css.json
# @echo  "analyze-css"
# @node -pe "\
# R = require('./$(LOG_DIR)/analyze-css.json').metrics;" > $@

