# BUILD PHASE
###############################################################################
# pull request merged and now on master:
# update semver TODO! discuss how this is done
# update config
# interpolation 'semver and config' vars into template and place in build
# copy over other changed package files into build
# everything else (templates, modules , resources ) should be already there
# update xar  TODO! might have to recurse to update version
#   $(CONFIG_FILE) $(PKG_TEMPLATES) $(PKG_MAIN) $(XAR)
#
# @gh update-semver
###############################################################################
# BUILD TARGET PATTERNS
#==========================================================

SRC_PKG_TMPL := $(P)/repo.xml $(P)/expath-pkg.xml
PKG_TEMPLATES := $(patsubst $(P)/%, $(B)/%, $(SRC_PKG_TMPL))
SRC_PKG_XQ := $(shell find $(P) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(P) -name '*.xconf*')
SRC_PKG_MAIN := $(SRC_PKG_XCONF) $(SRC_PKG_XQ)
PKG_MAIN := $(patsubst $(P)/%, $(B)/%, $(SRC_PKG_MAIN))

# $(info $(PKG_MAIN))
.PHONY: pre-build package-clean

pre-build:
	@mkdir -p $(B)/modules/{api,lib,render} 
	@mkdir -p $(B)/templates/{pages,includes} 
	@echo 'copy over essential api modules'
	@cp  modules/api/* $(B)/modules/api 
	@echo 'copy over essential lib modules'
	@cp modules/lib/archive.xqm $(B)/modules/lib
	@cp modules/lib/note.xqm $(B)/modules/lib
	@echo 'copy over essential home page template'
	@cp templates/pages/home.html $(B)/templates/pages
	@echo 'copy over essential include templates'
	@cp templates/includes/head.html $(B)/templates/includes
	@echo 'copy render modules called in *includes* for home-page '
	@cp modules/render/* $(B)/modules/render


build: $(PKG_TEMPLATES) $(PKG_MAIN)

# $(TEMPLATES) $(MODULES) $(STYLES)

package: $(XAR)

package-clean: 
	@rm $(XAR)



$(B)/expath-pkg.xml: $(P)/expath-pkg.xml config
	@echo  "MODIFY $@"
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('package').attr('name', '$(NAME)');\
 n('package').attr('abbrev', '$(ABBREV)');\
 n('package').attr('version', '$(VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(NAME)');\
 require('fs').writeFileSync('./$@', n.xml() )"
	@cat $@
	@echo "------------------------------------------------------------------ "



# Create package with zip
# but exclude the data dir
# TODO! might also exclude binary media
$(XAR): $(wildcard $(B)/* )
	@echo "##[ $@ ]##"
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(B); zip -r ../$@ . -x 'data/archive/*' 'data/pages/*'
	@echo "------------------------------------------------------------------ "

test-packaging:
	@echo 'TEST PACKAGING'
	@prove t/packaging.t
	@echo "------------------------------------------------------------------ "

PHONY: test-packaging
