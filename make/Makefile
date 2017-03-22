SHELL=/bin/bash
include config
include ../common.properties
include ../mk-project.properties
export PATH := $(abspath ../bin):$(abspath ../node_modules/.bin):$(PATH)

# keep intermediate files
# http://stackoverflow.com/questions/3046117/gnu-makefile-multiple-outputs-from-single-rule-preventing-intermediate-files
.SECONDARY:

#{{{
# Make sure we have the following apps installed:
APP_LIST = git curl node expect tidy scour
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))


# HOST_REMOTE := $(shell  dig +short $(GIT_REPO_NAME) )
# CURRENT_BRANCH := $(shell git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///')
# live reload
# check if livereload active
PID_TINY_LR := tiny-lr.pid
ifneq ($(wildcard $(PID_TINY_LR)),)
  TINY-LR_UP :=  $(shell ps "$$(<$(PID_TINY_LR))" | awk '/tiny-lr/{print $$1,$$5}')
else
  TINY-LR_UP :=
endif

# VERSION = $(shell echo $$(gh latest-tag | sed 's/v//'))
VERSION != echo "$(SEMVER)" | sed 's/v//'
XAR != echo "$(D)/$(ABBREV)-$(VERSION).xar"
# GIT_USER := $(shell git config --get user.name )
# GIT_EMAIL := $(shell git config --get user.email )
# # REPO 
# REPO_BASE_URL := https://api.github.com
# GIT_REMOTE_ORIGIN_URl := $(shell git config --get remote.origin.url )
# GIT_REPO_FULL_NAME := $(shell echo $(GIT_REMOTE_ORIGIN_URl) | sed -e 's/git@github.com://g' | sed -e 's/\.git//g' )
# GIT_REPO_NAME := $(shell  echo $(GIT_REPO_FULL_NAME) |cut -d/ -f2 )
# GIT_REPO_OWNER_LOGIN := $(shell  echo $(GIT_REPO_FULL_NAME) |cut -d/ -f1 )
# GITHUB_ACCESS_TOKEN := $(shell  <../.github-access-token)
# SITE_ACCESS_TOKEN := $(shell <../.site-access-token)
# WEBSITE := https://$(GIT_REPO_NAME)
ifeq ($(TRAVIS_BRANCH),)
 CURRENT_BRANCH := $(shell git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///' )
else
 CURRENT_BRANCH :=
endif

ifneq ($(CURRENT_BRANCH),master)
 PARSED_ISSUE_LABEL := $(shell echo  "$(CURRENT_BRANCH)" |cut -d\- -f1)
 PARSED_ISSUE_NUMBER := $(shell echo  "$(CURRENT_BRANCH)" |cut -d\- -f2)
 PARSED_ISSUE_TITLE := $(shell echo $(CURRENT_BRANCH) |grep -oP '[a-z]{1,10}+-[0-9]{1,4}-\K(.+)' | tr '-' ' ')
endif

ifeq ($(TRAVIS_REPO_SLUG),)
 REPO_SLUG := $(shell git remote -v | grep -oP ':\K.+(?=\.git)' | head -1)
else
 REPO_SLUG := $(TRAVIS_REPO_SLUG)
endif

OWNER := $(shell echo  "$(REPO_SLUG)" |cut -d/ -f1)
REPO := $(shell echo  "$(REPO_SLUG)" |cut -d/ -f2)
API_REPO := $(REPO_BASE_URL)/repos/$(REPO_SLUG)
#derived vars
CURRENT_DATE  != date "+%Y-%m-%d"
CURRENT_DATE_TIME != date "+%Y-%m-%dT%H:%M:%S"

# common functions
empty :=
space := $(empty) $(empty)

cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))";fi )

rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
#~/.config/nvim/words/ns-funcs.thesaurus}}}
TASKS_DIR := .tasks
fo := $(TASKS_DIR)/repo.mk $(TASKS_DIR)/build.mk
include $(filter-out $(fo) ,$(wildcard $(TASKS_DIR)/*.mk))
include $(TASKS_DIR)/repo.mk

default: help

.PHONY: help
