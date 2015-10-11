#==========================================================
#  POSTS MARKDOWN TO DATA
# pages can
#==========================================================
WWW_POSTS_DIR := content/posts
TEMP_POSTS_DIR := $(TEMP_DIR)/md/posts
DATA_POSTS_DIR := $(DATA_DIR)/archive

DATA_ARCHIVE_DIR := $(DATA_DIR)/archive

#MARKDOWN
SRC_POSTS := $(shell find $(WWW_POSTS_DIR) -name '*.md'  )
OUT_TEMP_POSTS := $(patsubst $(WWW_POSTS_DIR)/%, $(TEMP_POSTS_DIR)/%, $(SRC_POSTS))
OUT_TEMP_ARTICLES := $(patsubst $(WWW_POSTS_DIR)/articles/%, $(TEMP_POSTS_DIR)/articles/%, $(SRC_POSTS))
OUT_DATA_POSTS := $(foreach src,$(SRC_POSTS), $(addprefix $(DATA_POSTS_DIR)/,$(subst -,/,$(shell echo $(notdir $(src) ) | grep -oP '\d{4}-\d{2}-\d{2}')))/$(shell echo $(notdir $(src)) | grep -oP '\d{4}-\d{2}-\d{2}-\K[a-z-]+').xml )

# POSTX := $(patsubst $(DATA_ARCHIVE_DIR)/%.xml,$(BUILD_DIR)/$(DATA_POSTS_DIR)/%.xml , $(shell find $(DATA_ARCHIVE_DIR) -name '*.xml'  ))

############################################################
# functions
STORED_POST != tail -n 1 $(POSTS_STORED_LOG)

date_dir = $(addprefix $1/,$(subst -,/,$(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}')))
url_dir = $(subst -,/,$(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}'))
parse_name = $(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}-\K[a-z-]+')
parse_date = $(shell echo "$1" | grep -oP '\d{4}-\d{2}-\d{2}')
parse_post_type = $(shell echo "$1" | grep -oP 'article')
tag_uri = tag:$(NAME),$(call parse_date,$1):article:$(call parse_name,$1)
archive_url = http://$(NAME)/archive/$(call url_dir,$1)/$(call parse_name,$1).html
archive_file = $(DATA_POSTS_DIR)/$(call url_dir,$1)/$(call parse_name,$1).xml

LOGGED_TRIGGER != tail -n 1 $(LOG_DIR)/trigger.log
############################################################
#
OUT_POSTS :=  $(OUT_TEMP_ARTICLES)  $(POSTS_STORED_LOG) 

# $(POSTS_STORED_LOG)

posts: $(OUT_POSTS)

watch-posts:
	@watch $(MAKE) posts

.PHONY: watch-posts posts-help

posts-help:
	@echo SRC_POSTS $(SRC_POSTS)
	@echo '---------------------------------------------------------------------'
	@echo POSTS_STORED_LOG: $(POSTS_STORED_LOG)
	@echo "file: $(word 1, $(call STORED_POST))"   
	@echo "eXist:  $(word 2, $(call STORED_POST))"   
	@echo '---------------------------------------------------------------------'
	@echo eXist log $(notdir $(XMLDB_LOG) )
	@echo eXist last item stored $(STORED)
	@echo '---------------------------------------------------------------------'
	@echo eXist app log $(LOG_DIR)/trigger.log 
	@echo eXist last logged trigger
	@tail -n 1 $(LOG_DIR)/trigger.log
# @echo eXist app log last item $(call LOGGED_APP)

# whenever an article is changed in the content/posts/articles dir
# 

$(TEMP_POSTS_DIR)/articles/%: $(WWW_POSTS_DIR)/articles/%
	@echo "MD to XML DATA"
	@echo "md in: [ $(<) ]"
	@echo "TASK! md stripped of frontmatter"
	@echo "md out: [ $(@) ]"
	@echo "mkdir: [ $(@D) ]"
	@mkdir -p $(@D)
	@echo $(notdir $<)
	@echo parse date: $(call parse_date,$<)
	@echo parse name: $(call parse_name,$<)
	@echo date url dir: $(call url_dir,$<)
	@echo parse post type: $(call parse_post_type,$<)
	@echo tag-uri: $(call tag_uri,$<)
	@echo $(notdir $<)
	@echo "mkdir: [ $(dir $(call archive_file,$<)) ]"
	@mkdir -p $(dir $(call archive_file,$<))
	@echo  "xml-out:  [ $(call archive_file,$<) ]"
	@sed '1 { /^<!--/ { :a N; /\n-->/! ba; d} }' $(<) > $(@)
	@node -pe "\
 R = require('ramda');\
 fs = require('fs');\
 fm = require('html-frontmatter')(fs.readFileSync('$<', 'utf-8'));\
 var n = require('cheerio').load(\
'<entry>\n<name/><summary/><author/><draft/><published/><updated/>\
 <url/><uid/><category/><location/><syndication/><in-reply-to/>\
 \n<content>\n' +\
 require('markdown-it')({\
 html: true,\
 linkify: true,\
 xhtmlOut: true,\
 typographer: true\
 }).render(fs.readFileSync('$@').toString()\
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
 if(R.prop('url', fm)){n('url').text(R.prop('url', fm))}else{n('url').text('$(call archive_url,$<)')};\
  if(R.prop('uid', fm)){n('url').text(R.prop('uid', fm))}else{n('uid').text('$(call tag_uri,$<)')};\
 if(R.prop('category', fm)){n('category').text(R.prop('category', fm))}else{n('category').remove()};\
 if(R.prop('location', fm)){n('location').text(R.prop('location', fm))}else{n('location').remove()};\
 if(R.prop('syndication', fm)){n('syndication').text(R.prop('syndication', fm))}else{n('syndication').remove()};\
 if(R.prop('in-reply-to', fm)){n('in-reply-to').text(R.prop('in-reply-to', fm))}else{n('in-reply-to').remove()};\
 n.xml()" > $(call archive_file,$<)
	@echo '--------------------------------------------------------------------'
	@node -pe "\
 fs = require('fs');\
 n = require('cheerio').load(fs.readFileSync('$(call archive_file,$<)'));\
 n.xml();"
	@echo '--------------------------------------------------------------------'
 
############################################################

 
$(POSTS_STORED_LOG): $(OUT_DATA_POSTS)
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
	@echo ' '

############################################################ 

#$(POSTS_UPLOADED_LOG): $(POSTS_STORED_LOG)
#	@echo " === upload into remote db === "
#	@echo local file: [ $(word 1,$(STORED_POST)) ]
#	@echo stored local resource [ $(word 2,$(STORED_POST)) ]
#	@node -pe "\
# fs = require('fs');\
# n = require('cheerio').load(fs.readFileSync('$(word 1,$(STORED_POST))'));\
# n('draft').text();"  | \
# grep 'no' && bin/xq -r store-app-data-content $(word 1,$(STORED_POST))
#	@node -pe "\
# fs = require('fs');\
# n = require('cheerio').load(fs.readFileSync('$(word 1,$(STORED_POST))'));\
# n('draft').text();" | \
# grep 'no' \
# && bin/xq -r store-app-data-content $(word 1,$(STORED_POST)) \
# || echo '... no upload required'; touch $(POSTS_UPLOADED_LOG)
#	@echo " -------------------------- "
