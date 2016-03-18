include config
include ../common.properties
SHELL=/bin/bash
export PATH := $(abspath $(BIN_DIR)):$(abspath $(NODE_BIN_DIR)):$(PATH)
# dir shortcuts
T := .temp
G := .github
L := .logs
B := build
D := deploy

#{{{
# Make sure we have the following apps installed:
APP_LIST = git curl node expect tidy
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))

ifneq ($(wildcard $(PID_TINY_LR)),)
  TINY-LR_UP :=  $(shell ps "$$(<$(PID_TINY_LR))" | awk '/tiny-lr/{print $$1,$$5}')
else
  TINY-LR_UP :=
endif

VERSION != echo "$(SEMVER)" | sed 's/v//'
XAR != echo "$(DEPLOY_DIR)/$(ABBREV)-$(VERSION).xar"

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

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
#}}}
fo := $(TASKS_DIR)/repo.mk $(TASKS_DIR)/scripts.mk $(TASKS_DIR)/icons.mk
include $(filter-out $(fo) ,$(wildcard $(TASKS_DIR)/*.mk))
include $(TASKS_DIR)/repo.mk
# include $(TASKS_DIR)/modules.mk\
# $(TASKS_DIR)/templates.mk\
# $(TASKS_DIR)/styles.mk\
# $(TASKS_DIR)/content.mk

# include $(TASKS_DIR)/build.mk
# include $(TASKS_DIR)/repo.mk

default: help

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
