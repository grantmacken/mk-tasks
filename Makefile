SHELL=/bin/bash

gmack :=  $(abspath ../gmack.nz)
WEB_PROJECTS := $(gmack)
UP_TARG_DIR := $(abspath ../ )
define ensure-exec
	@echo 'ensure executable'
	@chmod +x $(1)
endef

#build: $(MK_INC_TARG) $(PROPERTIES_TARG)  $(NODE_TARG) $(BASH_TARG) \
#  $(XQ_TARG) $(GH_TARG) $(TMX_TARG) $(WEB_PROJECTS) \
#  $(UP_TARG_DIR)/bin/ext

build:
	@mkdir -p $(UP_TARG_DIR)/bin
	@mkdir -p $(UP_TARG_DIR)/node_modules/.bin
	stow -t $(UP_TARG_DIR)/bin bin
	stow -t $(UP_TARG_DIR) properties
	stow -t $(UP_TARG_DIR) node
	stow -t $(gmack) make


clean:
	stow -D -t $(UP_TARG_DIR)/bin bin
	stow -D -t $(UP_TARG_DIR) properties
	stow -D -t $(UP_TARG_DIR) node
	stow -D -t $(gmack) make

install:
	@cd  $(UP_TARG_DIR) && npm install
