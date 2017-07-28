SHELL=/bin/bash
include config
UP_TARG_DIR := $(abspath ../)
define mkHelp
=========================================================

- `make`         use stow to create symlinks
- `make clean`   use stow to delete symlinks
- `make install` cd to uplevel dir and invoke npm 
- `make help`    this

UP DIR: $(UP_TARG_DIR)

Use config to list web project domains

=========================================================
endef

default: build

help: export mkHelp:=$(mkHelp)
help:
	@echo "$${mkHelp}"
	@echo ""
	@echo 'WEB PROJECTS'
	@echo '------------'
	@$(foreach project,$(WEB_PROJECTS),echo $(UP_TARG_DIR)/$(project);)

build:
	@echo "## $@ ##"
	@mkdir -p $(UP_TARG_DIR)/bin
	@stow -t $(UP_TARG_DIR)/bin bin
	@stow -t $(UP_TARG_DIR) properties
	@stow -t $(UP_TARG_DIR) node
	@$(foreach project,$(WEB_PROJECTS),stow -t $(UP_TARG_DIR)/$(project) make;)
	@$(foreach project,$(WEB_PROJECTS), mkdir -p $(UP_TARG_DIR)/$(project)/{\.github/headers,\.github/etags,\.tmp};)

clean:
	@stow -D -t  $(UP_TARG_DIR)/bin bin
	@stow -D -t $(UP_TARG_DIR) properties
	@stow -D -t $(UP_TARG_DIR) node
	@$(foreach project,$(WEB_PROJECTS),stow -D -t $(UP_TARG_DIR)/$(project) make;)
	@[ -d ../node_modules ] && rm -r ../node_modules || echo 'node modules already removed' 

install:
	@echo "link stuff that needs to be linked"
	@echo $(UP_TARG_DIR)
	@cd $(UP_TARG_DIR) && npm install

.PHONY: build clean install help
