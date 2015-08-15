#==========================================================
#  PAGES MARKDOWN TO DATA
# pages can
#==========================================================
WWW_PAGES_DIR := www/pages
TEMP_PAGES_DIR := $(TEMP_DIR)/md/pages
DATA_PAGES_DIR := $(DATA_DIR)/pages

#MARKDOWN
SRC_PAGES := $(call rwildcard,$(WWW_PAGES_DIR),*.md)
OUT_TEMP_PAGES := $(patsubst $(WWW_PAGES_DIR)/%, $(TEMP_PAGES_DIR)/%, $(SRC_PAGES))
OUT_DATA_PAGES := $(patsubst $(WWW_PAGES_DIR)/%.md, $(DATA_PAGES_DIR)/%.xml, $(SRC_PAGES))
OUT_PAGES :=  $(OUT_DATA_PAGES) $(OUT_BUILD_PAGES) $(OUT_BUILD_PAGES)
#############################################################

OUT_PAGES :=  $(OUT_TEMP_PAGES) $(OUT_DATA_PAGES) $(PAGES_STORED_LOG)

pages: $(OUT_PAGES)

watch-pages:
	@watch $(MAKE) pages

.PHONY:  watch-pages

#############################################################
#functions

postsArchiveURL=http://$(NAME)$1.html
postsTagURI=tag:$(NAME),$(CURRENT_DATE):page:$1
STORED_PAGE != tail -n 1 $(PAGES_STORED_LOG)

define xq-store-app-data-file
	@echo data-file: [ $(1) ]
	@xq store-app-data-file $(1)
	@echo local xmldb log: [ $(STORED) ]
	@echo stored page log: [ $(STORED_PAGE) ]
endef

$(TEMP_PAGES_DIR)%: $(WWW_PAGES_DIR)%
	@echo " === strip markdown of front-matter === "
	@echo "SRC $<"
	@echo "OUT $@"
	@mkdir -p $(@D)
	@echo $(TEMP_PAGES_DIR)
	@echo OUT_TEMP_PAGES: $(OUT_TEMP_PAGES)
	@echo  OUT_DATA_PAGES: $(OUT_DATA_PAGES)
	@echo  OUT_BUILD_PAGES: $(OUT_BUILD_PAGES)
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $< > $@

$(DATA_PAGES_DIR)%.xml: $(TEMP_PAGES_DIR)%.md
	@echo " === convert to xml === "
	@mkdir -p $(@D)
	@echo "MD to XML DATA"
	@echo "STEM: $*"
	@echo "READ FRONT-MATER: $(WWW_PAGES_DIR)$*.md"
	@echo "SRC $<"
	@echo "OUT $@"
	@echo "WWW_PAGES_DIR: $(WWW_PAGES_DIR)"
	@echo "DATA_PAGES_DIR: $(DATA_PAGES_DIR)"
	@mkdir -p $(@D)
	@node -pe "\
 R = require('ramda');\
 fs = require('fs');\
 fm = require('html-frontmatter')(fs.readFileSync('$(WWW_PAGES_DIR)$*.md', 'utf-8'));\
 var n = require('cheerio').load(\
'<entry>\n<name/><summary/><author/><draft/><published/><updated/>\
 <url/><uid/><category/><location/><syndication/><in-reply-to/>\
 \n<content>\n' +\
 require('markdown-it')({\
 html: true,\
 linkify: true,\
 xhtmlOut: true,\
 typographer: true\
 }).render(fs.readFileSync('$<').toString()\
 ) +\
 '\n</content>\n\
 </entry>',\
 {normalizeWhitespace: false,xmlMode: true}\
 );\
 if(R.prop('name', fm)){n('name').text(R.prop('name', fm))}else{n('name').text('$(call parse_name,$<)')};\
 if(R.prop('summary', fm)){n('summary').text(R.prop('summary', fm))}else{n('summary').remove()};\
 if(R.prop('author', fm)){n('author').text(R.prop('author', fm))}else{n('author').text('$(AUTHOR)')};\
 if(R.prop('draft', fm)){n('draft').text(R.prop('draft', fm))}else{n('draft').remove()};\
 if(R.prop('published', fm)){n('published').text(R.prop('published', fm))}else{n('published').text('$(CURRENT_DATE_TIME)')};\
 if(R.prop('updated', fm)){n('updated').text(R.prop('updated', fm))}else{n('updated').text('$(CURRENT_DATE_TIME)')};\
 if(R.prop('url', fm)){n('url').text(R.prop('url', fm))}else{n('url').text('$(call postsArchiveURL,$*)')};\
 if(R.prop('uid', fm)){n('url').text(R.prop('uid', fm))}else{n('uid').text('$(call postsTagURI,$*)')};\
 if(R.prop('category', fm)){n('category').text(R.prop('category', fm))}else{n('category').remove()};\
 if(R.prop('location', fm)){n('location').text(R.prop('location', fm))}else{n('location').remove()};\
 if(R.prop('syndication', fm)){n('syndication').text(R.prop('syndication', fm))}else{n('syndication').remove()};\
 if(R.prop('in-reply-to', fm)){n('in-reply-to').text(R.prop('in-reply-to', fm))}else{n('in-reply-to').remove()};\
 n.xml()" > $@
	@node -pe "\
 fs = require('fs');\
 n = require('cheerio').load(fs.readFileSync('$@'));\
 n.xml();"
	@echo " -------------------------- "

$(PAGES_STORED_LOG): $(OUT_DATA_PAGES)
	@echo " === store into local db === "
	@echo "MODIFIED SRC $?"
	@echo "COUNT MODIFIED $(words $?)"
	@$(foreach src,$?,$(call xq-store-app-data-file,$(src)))
	@echo " -------------------------- "
ifeq ($(TINY-LR_UP),)
	@echo tin-lr NOT up
else ifneq ($(STORED),)
	@echo " === live reload === "
	@echo tiny-lr is UP [ $(TINY-LR_UP) ]
	@echo and is STORED in xmldb [ $(STORED) ]
	@echo 'attempt to ping tiny-lr server'
	@curl -s --ipv4 http://localhost:35729/changed?files=$(shell node -pe '"$?".split(" ").join(",")')
endif
	@echo '-----------------------'

#@$(file >> $(PAGES_STORED_LOG),$?)

#$(PAGES_UPLOADED_LOG): $(PAGES_STORED_LOG)
#	@echo " === upload into remote db === "
#	@echo local file: [ $(word 1,$(STORED_PAGE)) ]
#	@echo stored local resource [ $(word 2,$(STORED_PAGE)) ]
#	@node -pe "\
# fs = require('fs');\
# n = require('cheerio').load(fs.readFileSync('$(word 1,$(STORED_PAGE))'));\
# n('draft').text();" | \
# grep 'no' \
# && bin/xq -r store-app-data-content $(word 1,$(STORED_PAGE)) \
# || echo '... no upload required'; touch $(PAGES_UPLOADED_LOG)
#	@echo " -------------------------- "
