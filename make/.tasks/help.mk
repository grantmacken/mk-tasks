define mkHelp
=========================================================
WEBSITE PROJECT: $(NAME) 
PROJECT OWNER: $(OWNER)
CREATED BY: $(AUTHOR)
DESCRIPTION: $(DESCRIPTION)
---------------------------------------------------------
 mk-task are a bundle of calls to make targets which aim to
 create a deployable eXist website app.

source folders
 - modules
 - templates
 - resources
   - icons
   - scripts
   - styles

workflow phases
- building  -  async watch targets
     -> lint | compile | optimise 
     -> build folder - cleaned assets
     -> up to eXist dev
     -> functional tests | live reload
- deploying
  - xar -> github release asset ->  install and deploy xar into eXist prod and dev

working with github api

TASKS : make tasks that can be invoked in this repo

- repo

==========================================================
endef

help: export mkHelp:=$(mkHelp)
help:
	@echo "$${mkHelp}"

help-env:
	@printenv

help-var:
	@echo 'BIN_DIR ': $(abspath ../bin)
	@echo 'SAXON ': $(SAXON)
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

.PHONY: help 

