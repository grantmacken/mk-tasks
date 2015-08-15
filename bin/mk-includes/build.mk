#==========================================================
#  Build and XAR creation
# modify repo.xml and expath-pkg.xml
# inplace when semver or config changes
# version comes from 'cat .semver' created from ... TODO'
#
#==========================================================
# SOURCES
#==========================================================
#
SRC_CONFIG := $(CONFIG_FILE)
SRC_SEMVER := $(SEMVER_FILE)
SRC_PKG_XQ := $(shell find $(PKG_DIR) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(PKG_DIR) -name '*.xconf*')
SRC_PKG_XML := $(PKG_DIR)/repo.xml $(PKG_DIR)/expath-pkg.xml
SRC_PKG_ROOT := $(SRC_PKG_XML) $(SRC_PKG_XCONF) $(SRC_PKG_XQ)


#==========================================================
# BUILD TARGET PATTERNS
#==========================================================

PKG_ROOT := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_ROOT))
ROOT_PKG_JSON := package.json

#############################################################

build: $(ROOT_PKG_JSON) $(SRC_PKG_ROOT) $(PKG_ROOT) $(XAR)

.PHONY: watch-build

#@watch -q $(MAKE) icons
watch-build:
	@watch -q $(MAKE) build

.PHONY:  watch-build

#############################################################

# use cheerio as xml parser
$(PKG_DIR)/repo.xml: $(SRC_CONFIG) $(SRC_SEMVER)
	@echo  "MODIFY $@"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$@').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('description').text('$(DESCRIPTION)');\
 n('author').text('$(AUTHOR)');\
 n('website').text('$(WEBSITE)');\
 n('target').text('$(REPO)');\
 require('fs').writeFileSync('$@', n.xml() )"

$(PKG_DIR)/expath-pkg.xml: $(SRC_CONFIG) $(SRC_SEMVER)
	@echo  "MODIFY $@"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$@').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('package').attr('name', '$(REPO)');\
 n('package').attr('abbrev', '$(ABBREV)' );\
 n('package').attr('version', '$(VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(REPO)');\
 require('fs').writeFileSync('./$@', n.xml() )"

$(ROOT_PKG_JSON): $(SRC_CONFIG) $(SRC_SEMVER)
	@echo  "MODIFY $@"
	@echo  "SRC  $<"
	@node -e "\
  var j = require('./$@');\
  j.version = '$(VERSION)';\
  j.name = '$(REPO)';\
  j.description = '$(DESCRIPTION)';\
  j.author = '$(AUTHOR)';\
  var s = JSON.stringify(j, null, 2);\
  require('fs').writeFileSync('./$@', s);"

# Copy over package root files
$(BUILD_DIR)/%: $(PKG_DIR)/%
	@mkdir -p $(dir $@)
	@echo "FILE $@ $<"
	@cp $< $@

$(XAR): $(wildcard $(BUILD_DIR)/* )
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(BUILD_DIR); zip -r ../$@ .
