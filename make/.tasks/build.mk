
###############################################################################
# BUILD PHASE
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

SRC_PKG_TMPL := $(PKG_DIR)/repo.xml $(PKG_DIR)/expath-pkg.xml
PKG_TEMPLATES := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_TMPL))
SRC_PKG_XQ := $(shell find $(PKG_DIR) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(PKG_DIR) -name '*.xconf*')
SRC_PKG_MAIN := $(SRC_PKG_XCONF) $(SRC_PKG_XQ)
PKG_MAIN := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_MAIN))

build: $(PKG_TEMPLATES) $(PKG_MAIN) $(TEMPLATES) $(MODULES) $(STYLES)

package: $(XAR)

# $(SEMVER_FILE): $(JSN_MERGE)
# 	@echo "##[ $@ ]##"
# 	@echo "upon merge create a new semver file for release"
# ifeq ($(PR_MERGED),true)
# 	@echo  $(PR_MERGED)
# 	@echo  $(PR_MILESTONE_TITLE)
# 	@gh update-semver "$$(xq -r app-semver | sed 's/v//' )" "$(PR_MILESTONE_TITLE)" | tee  $@
# endif

# $(CONFIG_FILE): $(SEMVER_FILE)
# 	@echo "##[ $@ ]##"
# 	@echo "whenever semver changes touch config so we get a fresh build"
# 	@echo "$$(<$@)"
# 	@touch $@
# 	@echo "------------------------------------------------------------------ "

# use cheerio as simple xml parser
$(BUILD_DIR)/repo.xml: $(PKG_DIR)/repo.xml $(CONFIG_FILE) $(SEMVER_FILE)
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('description').text('$(DESCRIPTION)');\
 n('author').text('$(AUTHOR)');\
 n('website').text('$(WEBSITE)');\
 n('target').text('$(NAME)');\
 require('fs').writeFileSync('./$@', n.xml() )"
	@echo "------------------------------------------------------------------ "

$(BUILD_DIR)/expath-pkg.xml: $(PKG_DIR)/expath-pkg.xml $(CONFIG_FILE)  $(SEMVER_FILE)
	@echo  "MODIFY $@"
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('package').attr('name', '$(WEBSITE)');\
 n('package').attr('abbrev', '$(ABBREV)');\
 n('package').attr('version', '$(VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(NAME)');\
 require('fs').writeFileSync('./$@', n.xml() )"
	@echo "------------------------------------------------------------------ "


# Copy over package root files
$(BUILD_DIR)/%: $(PKG_DIR)/%
	@mkdir -p $(dir $@)
	@echo "FILE $@ $<"
	@cp $< $@
	@echo "------------------------------------------------------------------ "

# Create package with zip
# but exclude the data dir
# TODO! might also exclude binary media
$(XAR): $(wildcard $(BUILD_DIR)/* )
	@echo "##[ $@ ]##"
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(BUILD_DIR); zip -r ../$@ . -x 'data*'
	@echo "------------------------------------------------------------------ "

test-packaging:
	@echo 'TEST PACKAGING'
	@prove t/packaging.t
	@echo "------------------------------------------------------------------ "

PHONY: test-packaging
