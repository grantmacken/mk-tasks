include config
include ../common.properties
SHELL=/bin/bash
#SHELL += -x
#SHELL := $(SHELL) -e
#export PATH := $(abspath $(NODE_BIN_DIR))/:$(PATH)
#export PATH := $(abspath $(BIN_DIR))/:$(PATH)

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

STORED != tail -n 1 $(XMLDB_LOG) | grep -oP 'storing document \K(.+)'

#recurcive wildcard function
## $(call rwildcard,$(WWW_PAGES_DIR),*.md)
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

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
VERSION := $(shell cat $(SEMVER_FILE))
SRC_BUILD := $(wildcard $(BUILD_DIR)/* )
XAR := $(PKG_DIR)/xar/$(ABBREV)-$(VERSION).xar

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

include $(TASKS_DIR)/*.mk

default: help

help:
	@echo printenv
	@echo 'NODE_BIN_DIR ': $(abspath $(NODE_BIN_DIR))
	@echo 'REPO_SLUG': $(REPO_SLUG)
	@echo 'OWNER': $(OWNER)
	@echo 'REPO': $(REPO)
	@echo 'DESCRIPTION: $(DESCRIPTION)'
	@echo 'ABBREV: $(ABBREV)'
	@echo 'WEBSITE: $(WEBSITE)'
	@echo 'API_REPO' $(API_REPO)
	@echo 'CURRENT_BRANCH $(CURRENT_BRANCH)'
	@echo 'NEXT RELEASE VERSION $(VERSION)'
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


tmx:
	@tmx

#ifneq ($(wildcard $(GH_REPO)),)
#	@echo 'GH_REPO: $(GH_REPO)'
#endif
#ifneq ($(wildcard $(GH_ISSUE)),)
#	@echo 'ISSUE_COMMENTS $(ISSUE_COMMENTS)'
#	@echo 'ISSUE_STATE $(ISSUE_STATE)'
#endif
#
POSTS := $(OUT_POSTS)
PAGES := $(OUT_PAGES)
STYLES := $(OUT_STYLES)
SCRIPTS := $(JS_SCRIPTS)
ICONS := $(ICONS_MAIN)

#$(POSTS) $(PAGES)  $(SCRIPTS) $(ICONS)
www: $(STYLES) $(PAGES)
#
watch-www:
	@watch -q $(MAKE) www

.PHONY:  watch-www tmx help


test:
	@prove
