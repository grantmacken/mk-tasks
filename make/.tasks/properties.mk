GIT_USER := $(shell  git config --get user.name )
GIT_EMAIL := $(shell  git config --get user.email )
GIT_REMOTE_ORIGIN_URl := $(shell git config --get remote.origin.url )
GIT_REPO_FULL_NAME := $(shell  echo $(GIT_REMOTE_ORIGIN_URl) | sed -e 's/git@github.com://g' | sed -e 's/\.git//g' )
GIT_REPO_NAME := $(shell echo $(GIT_REPO_FULL_NAME) |cut -d/ -f2 )
GIT_REPO_OWNER_LOGIN := $(shell echo $(GIT_REPO_FULL_NAME) |cut -d/ -f1 )
GITHUB_ACCESS_TOKEN := $(shell echo "$$(<../.github-access-token)")
SITE_ACCESS_TOKEN := $(shell echo "$$(<../.site-access-token)")
WEBSITE := https://$(GIT_REPO_NAME)
# HOST_REMOTE := $(shell dig @8.8.8.8 +short $(GIT_REPO_NAME))
# REPO declared in ../common.properties
# REPO_BASE_URL := https://api.github.com
API_REPO="$(REPO_BASE_URL)/repos/$(GIT_REPO_FULL_NAME)"
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
# live reload
# check if livereload active
PID_TINY_LR := tiny-lr.pid
ifneq ($(wildcard $(PID_TINY_LR)),)
  TINY-LR_UP :=  $(shell ps "$$(<$(PID_TINY_LR))" | awk '/tiny-lr/{print $$1,$$5}')
else
  TINY-LR_UP :=
endif

VERSION != echo "$(SEMVER)" | sed 's/v//'
XAR != echo "$(D)/$(ABBREV)-$(VERSION).xar"
CURRENT_DATE  != date "+%Y-%m-%d"
CURRENT_DATE_TIME != date "+%Y-%m-%dT%H:%M:%S"
