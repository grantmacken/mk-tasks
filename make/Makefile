include config
include ../common.properties
SHELL=/bin/bash
export PATH := $(abspath $(BIN_DIR)):$(abspath $(NODE_BIN_DIR)):$(PATH)

#CURRENT_MAKEFILE := $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
#MAKEFILE_DIRECTORY := $(dir $(CURRENT_MAKEFILE))
# misc functions
# Make sure we have the following apps installed:
APP_LIST = git curl node
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))

ifneq ($(wildcard $(PID_TINY_LR)),)
  TINY-LR_UP :=  $(shell ps "$$(<$(PID_TINY_LR))" | awk '/tiny-lr/{print $$1,$$5}')
else
  TINY-LR_UP :=
endif

ifeq ($(wildcard $(SEMVER_FILE)),)
 $(file > $(SEMVER_FILE),v0.0.0)
endif

VERSION != echo "$$(<$(SEMVER_FILE))" | sed 's/v//'
XAR != echo "$(PKG_DIR)/xar/$(ABBREV)-$(VERSION).xar"


ifeq ($(TRAVIS_BRANCH),)
 CURRENT_BRANCH := $(shell git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///' )
else
 CURRENT_BRANCH :=
endif

#
ifneq ($(CURRENT_BRANCH),master)
 PARSED_ISSUE_LABEL := $(shell echo  "$(CURRENT_BRANCH)" |cut -d\- -f1)
 PARSED_ISSUE_NUMBER := $(shell echo  "$(CURRENT_BRANCH)" |cut -d\- -f2)
 PARSED_ISSUE_TITLE := $(shell echo $(CURRENT_BRANCH) |grep -oP '[a-z]{1,10}+-[0-9]{1,4}-\K(.+)' | tr '-' ' ')
endif
#
SRC_BUILD := $(wildcard $(BUILD_DIR)/* )

ifeq ($(TRAVIS_REPO_SLUG),)
 REPO_SLUG := $(shell git remote -v | grep -oP ':\K.+(?=\.git)' | head -1)
else
 REPO_SLUG := $(TRAVIS_REPO_SLUG)
endif

OWNER := $(shell echo  "$(REPO_SLUG)" |cut -d/ -f1)
REPO := $(shell echo  "$(REPO_SLUG)" |cut -d/ -f2)
API_REPO := $(REPO_BASE_URL)/repos/$(REPO_SLUG)
#derived vars
WEBSITE := http://$(REPO)
CURRENT_DATE  != date "+%Y-%m-%d"
CURRENT_DATE_TIME != date "+%Y-%m-%dT%H:%M:%S"

# common functions
empty :=
space := $(empty) $(empty)

getMimeType = $(shell node -pe "\
 fs = require('fs');\
 re = /$1/;\
 n = require('cheerio').load(fs.readFileSync('$(EXIST_HOME)/mime-types.xml'),\
 { normalizeWhitespace: true, xmlMode: true});\
 n('extensions').filter(function(i, el){\
 return re.test(n(this).text());\
 }).parent().attr('name');\
")

#recurcive wildcard function
## $(call rwildcard,$(WWW_PAGES_DIR),*.md)
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

# store resource into eXist 
#
# called from 'for each' modified 
# 2 params in out
# "SRC  $? "
# "output log: $@"
# xq store-built-resource has 4 args
# "eXist collection_uri: $(join apps/,$(REPO))"
# "directory in file system: $(abspath  $(subst /$(subst build/,,$?),,$?))"
# "eXist store pattern: : $(subst build/,,$?) "
# "mime-type: $(call getTemplatesTestDir,$(suffix $(notdir $?)))"
# "log-name: $(basename $(notdir $@))" 
#  Note: eXist contructs path from apps collection 

# storeAppResource = $(shell xq store-built-resource \
#  '$(join apps/,$(REPO))' \
#  '$(abspath  $(subst /$(subst build/,,$1),,$1))' \
#  '$(subst build/,,$1)' \
#  '$(call getMimeType,$(suffix $(notdir $1)))' \
#  '$(basename $(notdir $2))' && tail -n 1  $2 )

#==========================================================

# ifneq ($(wildcard $(JSN_ISSUE)),)
# ISSUE_NUMBER !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.number'    
# ISSUE_TITLE !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.title'    
# ISSUE_LABEL !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.labels[0] | .name'    
# ISSUE_NAME = $(subst $(space),-,$(ISSUE_LABEL) $(ISSUE_NUMBER) $(ISSUE_TITLE))
# endif                                                 

# ifneq ($(wildcard $(JSN_PULL_REQUEST)),)
# PR_MERGED !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.merged'    
# PR_TITLE !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.title'    
# PR_MILESTONE_TITLE != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .title'    
# PR_MILESTONE_DESCRIPTION != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .description'    
# PR_HEAD_REFERENCE  != echo $$(<$(JSN_PULL_REQUEST)) | jq '.head | .ref'
# PR_BODY !=  echo $$(<$(JSN_PULL_REQUEST)) | jq '.body | @sh'
# endif           

# ifneq ($(wildcard $(JSN_RELEASE)),)
# UPLOAD_URL != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.upload_url' | sed -r 's/\{.+//g'
# RELEASE_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.name'
# RELEASE_TAG_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.tag_name'
# RELEASE_UPLOAD_FILE != echo "$(PKG_XAR_DIR)/${RELEASE_NAME}.xar"
# RELEASE_UPLOAD_URL != echo "$(UPLOAD_URL)?name=${RELEASE_NAME}.xar&label=${RELEASE_NAME}"
# endif           

# ifneq ($(wildcard $(JSN_LATEST_RELEASE)),)
# TAG_NAME != echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.tag_name'
# BROWSER_DOWNLOAD_URL != echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.assets[0] | .browser_download_url'
# endif           

# ifneq ($(wildcard $(JSN_DEPLOYMENT)),)
# DEPLOYMENT_ID != echo "$$(<$(JSN_DEPLOYMENT))" | jq -r -c '.id'
# endif           

#==========================================================
ifneq ($(wildcard $(TASKS_DIR)/*.mk),)
 include $(TASKS_DIR)/*.mk
endif

default: help

help:
	@printenv
	@echo 'NODE_BIN_DIR ': $(abspath $(NODE_BIN_DIR))
	@echo 'REPO_SLUG': $(REPO_SLUG)
	@echo 'OWNER': $(OWNER)
	@echo 'REPO': $(REPO)
	@echo 'DESCRIPTION: $(DESCRIPTION)'
	@echo 'ABBREV: $(ABBREV)'
	@echo 'WEBSITE: $(WEBSITE)'
	@echo 'API_REPO: $(API_REPO)'
	@echo 'CURRENT_BRANCH: $(CURRENT_BRANCH)'
	@echo 'VERSION: $(VERSION)'
ifneq ($(TRAVIS_TAG),)
	@echo 'TRAVIS_TAG: $(TRAVIS_TAG)'
endif
ifdef PARSED_ISSUE_NUMBER
	@echo 'PARSED_ISSUE_LABEL: $(PARSED_ISSUE_LABEL)'
	@echo 'PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)'
	@echo 'PARSED_ISSUE_TITLE: $(PARSED_ISSUE_TITLE)'
endif    
	@echo XAR $(XAR)
	@echo TINY-LR_UP $(TINY-LR_UP)

assets: $(STYLES)

site: $(BUILD_XQUERY_MODULES) $(BUILD_HTML_TEMPLATES)

watch-site:
	@watch -q $(MAKE) site

watch-assets:
	@watch -q $(MAKE) assets

watch-issue:
	@watch -q $(MAKE) issue

 test:
	@prove 

.PHONY: watch-issue watch-assets watch-site help
