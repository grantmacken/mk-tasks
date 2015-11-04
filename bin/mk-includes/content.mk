#==========================================================
# when notified of modified markdown content in CONTENT dir ->
# process and deliver converted markdown to xml to DATA dir ->
# then upload modified content to localhost preview server ->
# check if livereload server is running
# check if eXist has stored content via logs
#  if OK then  
#  ping server using livereload 
#
# NOTES: if NOT draft then PUT content on remo 
#    Upload to remote is handled by eXist localhost server
#  
#==========================================================
#############################################################
#functions

STORED_POST != tail -n 1 $(POSTS_STORED_LOG)
STORED_PAGE != tail -n 1 $(PAGES_STORED_LOG)
LOGGED_TRIGGER != tail -n 1 $(LOG_DIR)/trigger.log 
#
date_dir = $(addprefix $1/,$(subst -,/,$(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}')))
url_dir = $(subst -,/,$(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}'))
parse_name = $(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}-\K[a-z-]+')
parse_date = $(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}')
parse_post_type = $(shell echo "$1" | grep -oP 'article')
archiver =  $(call url_dir,$1)/$(call parse_name,$1)
#
parse_stem_name = $(shell echo "$1" | grep -oP '\d{4}/\d{2}/\d{2}/\K[a-z-]+')
parse_stem_date = $(shell echo "$1" | grep -oP '\d{4}/\d{2}/\d{2}')
archive_url = http://$(NAME)/archive/$(1)
archive_tag_uri = tag:$(NAME),$(subst /,-,$(call parse_stem_date, $1)):article:$(call parse_stem_name,$1)
#
postsArchiveURL=http://$(NAME)$1.html
postsTagURI=tag:$(NAME),$(CURRENT_DATE):page:$1

define store-build-content
	@echo data-file: [ $(1) ]
	@xq store-build-content $(1)
	@echo local xmldb log: [ $(STORED) ]
endef

define temp-archiver
	@echo modified [ $(1) ]
	@mkdir -p  $(addprefix $(TEMP_ARCHIVE_DIR)/, $(call url_dir,$(1)))    
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $(1) > $(addprefix $(TEMP_ARCHIVE_DIR)/,$(addsuffix .md, $(call archiver,$(1)))) 
	@node -pe "\
  fs = require('fs');\
  fm = require('html-frontmatter')(fs.readFileSync('$(1)', 'utf-8'));\
  JSON.stringify(fm);\
  " >  $(addprefix $(TEMP_ARCHIVE_DIR)/,$(addsuffix .json, $(call archiver,$(1)))) 
endef

#############################################################
CONTENT_PAGES_DIR := content/pages
TEMP_PAGES_DIR := $(TEMP_DIR)/$(CONTENT_PAGES_DIR)
DATA_PAGES_DIR := $(DATA_DIR)/pages

CONTENT_POSTS_DIR := content/posts
TEMP_ARCHIVE_DIR := $(TEMP_DIR)/content/archive
DATA_ARCHIVE_DIR := $(DATA_DIR)/archive
#MARKDOWN
SRC_PAGES := $(call rwildcard,$(CONTENT_PAGES_DIR),*.md)
TEMP_MD_ARTICLE_PAGES := $(patsubst $(CONTENT_PAGES_DIR)/%.md, $(TEMP_PAGES_DIR)/%.md, $(SRC_PAGES))
TEMP_FM_PAGES := $(patsubst $(CONTENT_PAGES_DIR)/%.md, $(TEMP_PAGES_DIR)/%.json, $(SRC_PAGES))
OUT_DATA_PAGES := $(patsubst $(CONTENT_PAGES_DIR)/%.md, $(DATA_PAGES_DIR)/%.xml, $(SRC_PAGES))
#
SRC_POSTS := $(call rwildcard,$(CONTENT_POSTS_DIR),*.md)
TEMP_MD_ARTICLE_POSTS :=  $(foreach src,$(SRC_POSTS),$(addprefix $(TEMP_ARCHIVE_DIR)/,$(addsuffix .md, $(call archiver,$(src)))))
TEMP_FM_ARTICLE_POSTS :=  $(foreach src,$(SRC_POSTS),$(addprefix $(TEMP_ARCHIVE_DIR)/,$(addsuffix .json, $(call archiver,$(src)))))
OUT_DATA_POSTS := $(foreach src,$(SRC_POSTS),$(addprefix $(DATA_ARCHIVE_DIR)/,$(addsuffix .xml, $(call archiver,$(src)))))    


OUT_PAGES :=  $(TEMP_MD_PAGES) $(TEMP_FM_PAGES) $(OUT_DATA_PAGES)\
 $(PAGES_STORED_LOG)

OUT_POSTS :=  $(TEMP_FM_ARTICLE_POSTS) $(TEMP_MD_ARTICLE_POSTS) $(OUT_DATA_POSTS)\
 $(POSTS_STORED_LOG)

# $(foreach src,$(OUT_POSTS),$(shell mkdir -p $(dir $(src))))

content: $(OUT_POSTS) $(OUT_PAGES)

watch-pages:
	@watch -q $(MAKE) content

.PHONY: postr  watch-content

info-content:
	@echo '========= info content =========='
	@echo $(TEMP_ARCHIVE_DIR)
	@echo SRC_POSTS $(SRC_POSTS)
	@echo $(TEMP_MD_ARTICLE_POSTS)
	@echo $(TEMP_FM_ARTICLE_POSTS)
	@echo $(OUT_DATA_POSTS)
	# @echo '---------------------------------------------------------------------'
# @echo POSTS_STORED_LOG: $(POSTS_STORED_LOG)
# @echo "file: $(word 1, $(call STORED_POST))"   
# @echo "eXist:  $(word 2, $(call STORED_POST))"   
# @echo '---------------------------------------------------------------------'
# @echo eXist log $(notdir $(XMLDB_LOG) )
# @echo eXist last item stored $(STORED)
# @echo '---------------------------------------------------------------------'
# @echo eXist app log $(LOG_DIR)/trigger.log 
# @echo eXist last logged trigger
# @tail -n 1 $(LOG_DIR)/trigger.log

#pages
$(TEMP_PAGES_DIR)%.md: $(CONTENT_PAGES_DIR)%.md
	@mkdir -p $(@D)
	@echo " === strip markdown of front-matter === "
	@echo "SRC $<"
	@echo "OUT $@"
	@echo $(TEMP_PAGES_DIR)
	@echo TEMP_MD_PAGES: $(TEMP_MD_PAGES)
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $< > $@ 

$(TEMP_PAGES_DIR)%.json: $(CONTENT_PAGES_DIR)%.md
	@mkdir -p $(@D)
	@echo " ===  get front-matter from doc === "
	@echo "SRC $<"
	@echo "OUT $@"
	@node -pe "\
 fs = require('fs');\
 fm = require('html-frontmatter')(fs.readFileSync('$(<)', 'utf-8'));\
 JSON.stringify(fm);\
  " > $@

$(DATA_PAGES_DIR)%.xml: $(TEMP_PAGES_DIR)%.md
	@echo " === convert to xml === "
	@mkdir -p $(@D)
	@echo "MD to XML DATA"
	@echo "STEM: $*"
	@echo "READ FRONT-MATER: $(TEMP_PAGES_DIR)$*.json"
	echo "SRC $<"
	echo "OUT $@"
	@echo "$$(<$(TEMP_PAGES_DIR)$*.json)" | jq -r -c '.'
	@echo " -------------------------- "
	@node -pe "\
  R = require('ramda');\
  fs = require('fs');\
  fm = require('./$(TEMP_PAGES_DIR)$(*).json');\
  var n = require('cheerio').load(\
 '<entry>\n<name/>\n<summary/>\n<author/\n><draft/>\n<published/>\n<updated/>\
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
	@$(foreach src,$?,$(call store-build-content,$(src)))
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

################################################################################
#posts articles frontmatter as json

$(TEMP_ARCHIVE_DIR)%.md  $(TEMP_ARCHIVE_DIR)%.json: $(SRC_POSTS)
	$(foreach src,$?,$(call temp-archiver,$(src)))

$(DATA_ARCHIVE_DIR)/%.xml: $(TEMP_ARCHIVE_DIR)/%.md 
	@mkdir -p $(@D)
	@echo "MD to XML DATA"
	@echo "md in: [ $(<) ]"
	@echo "xml out: [ $(@) ]"
	@echo "STEM: $*"  
	@echo "$$(<$(TEMP_ARCHIVE_DIR)/$*.json)" | jq -r -c '.'
	@echo " -------------------------- "
	@node -pe "\
  R = require('ramda');\
  fs = require('fs');\
  fm = require('./$(TEMP_ARCHIVE_DIR)/$(*).json');\
  var n = require('cheerio').load(\
 '<entry>\n<name/>\n<summary/>\n<author/\n><draft/>\n<published/>\n<updated/>\
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
  if(R.prop('name', fm)){n('name').text(R.prop('name', fm))}else{n('name').text('$(notdir $<)')};\
  if(R.prop('summary', fm)){n('summary').text(R.prop('summary', fm))}else{n('summary').remove()};\
  if(R.prop('author', fm)){n('author').text(R.prop('author', fm))}else{n('author').text('$(AUTHOR)')};\
  if(R.prop('draft', fm)){n('draft').text(R.prop('draft', fm))}else{n('draft').remove()};\
  if(R.prop('published', fm)){n('published').text(R.prop('published', fm))}else{n('published').text('$(CURRENT_DATE_TIME)')};\
  if(R.prop('updated', fm)){n('updated').text(R.prop('updated', fm))}else{n('updated').text('$(CURRENT_DATE_TIME)')};\
  if(R.prop('url', fm)){n('url').text(R.prop('url', fm))}else{n('url').text('$(call archive_url,$*)')};\
  if(R.prop('uid', fm)){n('url').text(R.prop('uid', fm))}else{n('uid').text('$(call archive_tag_uri,$*)))')};\
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


 $(POSTS_STORED_LOG): $(OUT_DATA_POSTS)
	@echo " === store into local db === "
	@echo "MODIFIED SRC $?"
	@echo "COUNT MODIFIED $(words $?)"
	@$(foreach src,$?,$(call store-build-content,$(src)))
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
