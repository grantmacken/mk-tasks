SHELL=/bin/bash

example :=  $(abspath ../example.com)
gmack :=  $(abspath ../gmack.nz)
WEB_PROJECTS := $(gmack)
UP_TARG_DIR := $(abspath ../)

info:
	@echo "$(UP_TARG_DIR)"

build:
	@mkdir -p $(UP_TARG_DIR)/bin
	stow -t $(UP_TARG_DIR)/bin bin
	stow -t $(UP_TARG_DIR) properties
	stow -t $(UP_TARG_DIR) node
	stow -t $(gmack) make

clean:
	@stow -D -t  $(UP_TARG_DIR)/bin bin
	@stow -D -t $(UP_TARG_DIR) properties
	@stow -D -t $(UP_TARG_DIR) node
	@stow -D -t $(gmack) make

install:
	@echo "link stuff that needs to be linked"
	@echo $(UP_TARG_DIR)
	@cd $(UP_TARG_DIR) && npm install


.PHONY: build clean install info
