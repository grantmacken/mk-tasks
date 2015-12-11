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
# $(call if_entry_exists,$@,updated)'

if_entry_exists = $(if $(wildcard $1),$(call entryText,$1,$2),$(call $2))

entryText = $(shell node -e " fs = require('fs'); \
 fs.access('$1',fs.R_OK | fs.W_OK, function (err) { \
 if (err) { console.log('$(call $2)'); return} ; \
 n = require('cheerio').load(fs.readFileSync('$1')); \
 if( typeof n('$2').text() == 'string'){ t = n('$2').text(); \
 if(t.trim()){console.log(n('$2').text())} \
 else{console.log('$(call $2)')}}});")

published = $(CURRENT_DATE_TIME)
updated = $(CURRENT_DATE_TIME)

#############################################################
POSTS_STORED_LOG=.logs/posts-stored.log
POSTS_RELOADED_LOG=.logs/posts-reloaded.json
POSTS_UPLOADED_LOG=.logs/posts-uploaded.log
STORED_LOG=.temp/stored.log
UPLOADED_LOG=.temp/uploaded.log
# POSTS
CONTENT_POSTS_DIR := content/posts
DATA_ARCHIVE_DIR := $(DATA_DIR)/archive
SRC_POSTS := $(call rwildcard,$(CONTENT_POSTS_DIR),*.md)
POSTS_ARTICLES :=  $(foreach src,$(SRC_POSTS),$(addprefix $(DATA_ARCHIVE_DIR)/,$(addsuffix .xml, $(call archiver,$(src)))))
POST_STORED_LOG := $(LOG_DIR)/posts-stored.log
POSTS_RELOADED_LOG := $(LOG_DIR)/posts-reloaded.json
OUT_POSTS := $(POSTS_ARTICLES) $(POSTS_STORED_LOG) $(POSTS_RELOADED_LOG)
# PAGES
CONTENT_PAGES_DIR := content/pages
DATA_PAGES_DIR := $(DATA_DIR)/pages
SRC_PAGES := $(call rwildcard,$(CONTENT_PAGES_DIR),*.md)
PAGES_ARTICLES := $(patsubst $(CONTENT_PAGES_DIR)/%.md, $(DATA_PAGES_DIR)/%.xml, $(SRC_PAGES))
PAGES_STORED_LOG := $(LOG_DIR)/pages-stored.log
PAGES_RELOADED_LOG := $(LOG_DIR)/pages-reloaded.json
OUT_PAGES :=  $(PAGES_ARTICLES) $(PAGES_STORED_LOG) $(PAGES_RELOADED_LOG) 

content: $(OUT_POSTS) $(OUT_PAGES)

watch-content:
	@watch -q $(MAKE) content

.PHONY:   watch-content

$(DATA_ARCHIVE_DIR)%.xml: $(SRC_POSTS)
	@echo "## $@ ##"
	@mkdir -p $(@D)
	@echo 'Check if there is already a post'
	@echo '$(wildcard $@)'
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $(<)  >  $(TEMP_DIR)/$(notdir $(<))
	@node -pe "\
 fs = require('fs');\
 fm = require('html-frontmatter')(fs.readFileSync('$(<)', 'utf-8'));\
 JSON.stringify(fm);\
  " | jq '.' > $(TEMP_DIR)/$(basename $(notdir $(<))).json
	@node -pe "\
  R = require('ramda');\
  fs = require('fs');\
  fm = require('./$(TEMP_DIR)/$(basename $(notdir $(<))).json');\
  var n = require('cheerio').load(\
 '<entry>\n<name/>\n<summary/>\n<author/\n><draft/>\n<published/>\n<updated/>\
  <url/><uid/><category/><location/><syndication/><in-reply-to/>\
  \n<content>\n' +\
  require('markdown-it')({\
  html: true,\
  linkify: true,\
  xhtmlOut: true,\
  typographer: true\
  }).render(fs.readFileSync('$(TEMP_DIR)/$(notdir $(<))').toString()\
  ) +\
  '\n</content>\n\
  </entry>',\
  {normalizeWhitespace: false,xmlMode: true}\
  );\
  if(R.prop('name', fm)){n('name').text(R.prop('name', fm))}else{n('name').text('$(notdir $<)')};\
  if(R.prop('summary', fm)){n('summary').text(R.prop('summary', fm))}else{n('summary').remove()};\
  if(R.prop('author', fm)){n('author').text(R.prop('author', fm))}else{n('author').text('$(AUTHOR)')};\
  if(R.prop('draft', fm)){n('draft').text(R.prop('draft', fm))}else{n('draft').remove()};\
  if(R.prop('published', fm)){n('published').text(R.prop('published', fm))}else{n('published').text('$(call if_entry_exists,$@,published)')};\
  if(R.prop('updated', fm)){n('updated').text(R.prop('updated', fm))}else{n('updated').text('$(call if_entry_exists,published,updated)')};\
  if(R.prop('url', fm)){n('url').text(R.prop('url', fm))}else{n('url').text('$(call archive_url,$*)')};\
  if(R.prop('uid', fm)){n('url').text(R.prop('uid', fm))}else{n('uid').text('$(call archive_tag_uri,$*)')};\
  if(R.prop('category', fm)){n('category').text(R.prop('category', fm))}else{n('category').remove()};\
  if(R.prop('location', fm)){n('location').text(R.prop('location', fm))}else{n('location').remove()};\
  if(R.prop('syndication', fm)){n('syndication').text(R.prop('syndication', fm))}else{n('syndication').remove()};\
  if(R.prop('in-reply-to', fm)){n('in-reply-to').text(R.prop('in-reply-to', fm))}else{n('in-reply-to').remove()};\
  n.xml()" > $@
	@node -pe "\
  n = require('cheerio').load(require('fs').readFileSync('$@'));\
  n.xml();"
	@echo "$(call if_post_exists,$@,published)"
	@rm $(TEMP_DIR)/$(notdir $(<)) $(TEMP_DIR)/$(basename $(notdir $(<))).json
	@rm $(TEMP_DIR)/$(notdir $(<)) $(TEMP_DIR)/$(basename $(notdir $(<))).md
	echo '------------------------------------------------------------------------'

 $(POSTS_STORED_LOG): $(POSTS_ARTICLES)
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC  $? "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join data/,$(REPO))"
	@echo "directory in file system: $(abspath $(DATA_DIR))"
	@echo "eXist store pattern: : $(subst $(DATA_DIR)/,,$?) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $?)))"
	@echo "log-name: $(basename $(notdir $@))"
	@echo '-----------------------'
	@xq store-built-resource \
 '$(join data/,$(REPO))' '$(abspath $(DATA_DIR))' \
 '$(subst $(DATA_DIR)/,,$?)' '$(call getMimeType,$(suffix $(notdir $?)))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(POSTS_RELOADED_LOG): $(POSTS_STORED_LOG)
	@echo "## $@ ##"
ifeq ($(TINY-LR_UP),)
	@echo 'tiny-lr NOT up'
else
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4 \
	http://localhost:35729/changed?files=$(shell tail -n 1 $<) | jq '.' > $@
endif
	@echo '-----------------------------------------------------------------'

###############################################################################
#
#    PAGES
#
#
#
###############################################################################
$(DATA_PAGES_DIR)%.xml: $(CONTENT_PAGES_DIR)%.md
	@echo "## $@ ##"
	@echo "SRC $<"
	@echo "OUT $@"
	@mkdir -p $(@D)
	@echo " ===  get front-matter from doc === "
	@node -pe "\
 JSON.stringify(require('html-frontmatter')(require('fs').readFileSync('$(<)', 'utf-8')))" | \
 jq '.' >  $(TEMP_DIR)/$(basename $<).json
	@echo " === strip markdown of front-matter === "
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $(<)  >  $(TEMP_DIR)/$(basename $<).md
	@node -pe "\
  var  fs = require('fs');\
  var m = require('./$(TEMP_DIR)/$(basename $<).json');\
  var n = require('cheerio').load(\
 '<entry>\n<name/>\n<summary/>\n<author/>\n<draft/>\n<published/>\n<updated/>\
 \n<url/>\n<uid/>\n<category/>\n<location/>\n<syndication/>\
 \n<content>\n' +\
  require('markdown-it')({\
  html: true,\
  linkify: true,\
  xhtmlOut: true,\
  typographer: true\
  }).render(fs.readFileSync('./$(TEMP_DIR)/$(basename $<).md').toString()) +\
  '\n</content>\n\
  </entry>',\
  {normalizeWhitespace: false,xmlMode: true}\
  );\
  if(m.name){n('name').text(m.name)}else{n('name').text('$(notdir $<)')};\
  if(m.summary){n('summary').text(m.summary)}else{n('summary').remove()};\
  if(m.author){n('author').text(m.author)}else{n('author').text('${AUTHOR}')};\
  if(m.draft){n('draft').text(m.draft)}else{n('draft').remove()};\
  if(m.category){n('category').text(m.category)}else{n('category').remove()};\
  if(m.location){n('location').text(m.location)}else{n('location').remove()};\
  if(m.syndication){n('syndication').text(m.syndication)}else{n('syndication').remove()};\
  n('published').text('$(call entryText,$@,published)');\
  if(m.updated){n('updated').text(m.updated)}else{n('updated').text('$(call entryText,$@,updated)')};\
  if(m.url){n('url').text(m.url)}else{n('url').text('http://$(NAME)$(*).html')};\
  if(m.uid){n('uid').text(m.uid)}else{n('uid').text('tag:$(NAME),$(call parse_date,$(call entryText,$@,published)):page:$(*)')};\
  n.xml()" | tidy -q -utf8 -xml -i > $@
	@node -pe "\
  fs = require('fs');\
  n = require('cheerio').load(fs.readFileSync('$@'));\
  n.xml();"


 $(PAGES_STORED_LOG): $(PAGES_ARTICLES)
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC  $? "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join data/,$(REPO))"
	@echo "directory in file system: $(abspath $(DATA_DIR))"
	@echo "eXist store pattern: : $(subst $(DATA_DIR)/,,$?) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $?)))"
	@echo "log-name: $(basename $(notdir $@))"
	@echo '-----------------------'
	@xq store-built-resource \
 '$(join data/,$(REPO))' '$(abspath $(DATA_DIR))' \
 '$(subst $(DATA_DIR)/,,$?)' '$(call getMimeType,$(suffix $(notdir $?)))' \
 '$(basename $(notdir $@))'
	@tail -n 1  $@
	@echo '-----------------------------------------------------------------'

$(PAGES_RELOADED_LOG): $(PAGES_STORED_LOG)
	@echo "## $@ ##"
ifeq ($(TINY-LR_UP),)
	@echo 'tin-lr NOT up'
else
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@curl -s --ipv4 \
	http://localhost:35729/changed?files=$(shell tail -n 1 $<) | jq '.' > $@
endif
	@echo '-----------------------------------------------------------------'

################################################################################

# xmlMeta := <name/>\n<summary/>\n<author/>/\n><draft/>\n<published/>\n<updated/><url/>\n<uid/>\n<category/>\n<location/>\n<syndication/>\n<in-reply-to/>


