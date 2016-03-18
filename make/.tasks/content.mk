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
SRC_POSTS := $(call rwildcard,content/posts,*.md)
DATA_POSTS :=  $(foreach src,$(SRC_POSTS),$(addprefix $(DATA_ARCHIVE_DIR)/,$(addsuffix .xml, $(call archiver,$(src)))))
POST_STORED_LOG := $(LOG_DIR)/posts-stored.log
POSTS_RELOADED_LOG := $(LOG_DIR)/posts-reloaded.json
OUT_POSTS := $(POSTS_ARTICLES) $(POSTS_STORED_LOG) $(POSTS_RELOADED_LOG)
# PAGES
CONTENT_PAGES_DIR := content/pages
DATA_PAGES_DIR := $(DATA_DIR)/pages
SRC_PAGES := $(call rwildcard,content/pages,*.md)
DATA_PAGES := $(patsubst content/pages/%.md, build/data/pages/%.xml, $(SRC_PAGES))

loggedPostsBuiltFile != [ -e  $(L)/posts-built.log ] && \
	tail -1 $(L)/posts-built.log

loggedPagesBuiltFile != [ -e  $(L)/pages-built.log ] && \
	tail -1 $(L)/pages-built.log
#
reload-posts:  $(L)/posts-reloaded.log

reload-pages:  $(L)/pages-reloaded.log

content: $(DATA_POSTS) $(DATA_PAGES)

watch-content:
	@watch -q $(MAKE) content

.PHONY:   watch-content

# $(DATA_ARCHIVE_DIR)%.xml: $(SRC_POSTS)
$(B)/data/archive%.xml: $(SRC_POSTS)
	@echo "## $@ ##"
	@echo "SRC $<"
	@echo "OUT $@"
	@echo "in dir $(dir $<)"
	@mkdir -p $(dir $@)
	@mkdir -p $(TEMP_DIR)/$(dir $<)
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
  if(m.url){n('url').text(m.url)}else{n('url').text('$(call archive_url,$*)')};\
  if(m.uid){n('uid').text(m.uid)}else{n('uid').text('$(call archive_tag_uri,$*)')};\
  n.xml()" > $@
	@node -pe "\
  n = require('cheerio').load(require('fs').readFileSync('$@'));\
  n.xml();"
	@$(file > $(L)/posts-built.log,$@)
	@$(MAKE) reload-posts
	echo '------------------------------------------------------------------------'

# echo "$(call if_post_exists,$@,published)"

$(L)/posts-stored.log: $(L)/posts-built.log
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server\
 so we get a live preview"
	@echo "SRC $(loggedPostsBuiltFile) "
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join data/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /$(subst build/data/,,$(loggedPostsBuiltFile)),,$(loggedPostsBuiltFile)))"
	@echo "eXist store pattern: $(subst build/data/,,$(loggedPostsBuiltFile)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(loggedPostsBuiltFile))))"
	@echo "log-name: $(basename $(notdir $@))" 
	@xq store-built-resource \
 '$(join data/,$(REPO))' \
 '$(abspath  $(subst /$(subst build/data/,,$(loggedPostsBuiltFile)),,$(loggedPostsBuiltFile)))' \
 '$(subst build/data/,,$(loggedPostsBuiltFile))' '$(call getMimeType,$(suffix $(notdir $(loggedPostsBuiltFile))))' \
 '$(basename $(notdir $@))'
	@echo '-----------------------------------------------------------------'

$(L)/posts-reloaded.log: $(L)/posts-stored.log
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@$(if  $(TINY-LR_UP), \
$(shell curl -s --ipv4  http://localhost:35729/changed?files=$$( tail -n 1 $<) | jq '.' > $@),\
echo 'tiny-lr NOT up' )
	@echo '-----------------------------------------------------------------'

###############################################################################
#
#    PAGES
#
#
#
###############################################################################
build/data/pages%.xml: content/pages%.md
	@echo "## $@ ##"
	@echo "SRC $<"
	@echo "OUT $@"
	@echo "in dir $(dir $<)"
	@mkdir -p $(dir $@)
	@mkdir -p $(TEMP_DIR)/$(dir $<)
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
  n.xml()"  > $@
	@node -pe "\
  n = require('cheerio').load(require('fs').readFileSync('$@'));\
  n.xml();"
	@$(file > $(L)/pages-built.log,$@)
	@$(MAKE) reload-pages

 $(L)/pages-stored.log: $(L)/pages-built.log
	@echo "## $@ ##"
	@echo "Store resource into our eXist local dev server so we get a live preview"
	@echo "SRC $(loggedPagesBuiltFile)"
	@echo "output log: $@"
	@echo "eXist collection_uri: $(join data/,$(REPO))"
	@echo "directory in file system: $(abspath  $(subst /$(subst build/data/,,$(loggedPagesBuiltFile)),,$(loggedPagesBuiltFile)))"
	@echo "eXist store pattern: $(subst build/data/,,$(loggedPagesBuiltFile)) "
	@echo "mime-type: $(call getMimeType,$(suffix $(notdir $(loggedPagesBuiltFile))))"
	@echo "log-name: $(basename $(notdir $@))"
	@xq store-built-resource \
'$(join data/,$(REPO))' \
'$(abspath  $(subst /$(subst build/data/,,$(loggedPagesBuiltFile)),,$(loggedPagesBuiltFile)))' \
'$(subst build/data/,,$(loggedPagesBuiltFile))' '$(call getMimeType,$(suffix $(notdir $(loggedPagesBuiltFile))))' \
'$(basename $(notdir $@))'
	@echo '-----------------------------------------------------------------'

$(L)/pages-reloaded.log: $(L)/pages-stored.log
	@echo "## $@ ##"
	@echo "Let livereload server know we have changed files"
	@echo "input log: $<"
	@echo "input log last item: $(shell tail -n 1 $<)"
	@echo "output log: $@"
	@$(if  $(TINY-LR_UP), \
$(shell curl -s --ipv4  http://localhost:35729/changed?files=$$( tail -n 1 $<) | jq '.' > $@),\
echo 'tiny-lr NOT up' )
	@echo '-----------------------------------------------------------------'

################################################################################
