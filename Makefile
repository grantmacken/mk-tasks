SHELL=/bin/bash

gmack :=  $(abspath ../gmack.nz/Makefile)
WEB_PROJECTS := $(gmack)

BASE := $(abspath . )
SRC_DIR := $(abspath . )

UP_TARG_DIR := $(abspath ../ )

MK := $(abspath bin/Makefile)
MK_INCLUDES := $(abspath $(wildcard bin/mk-includes/*))
MK_INC_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(MK_INCLUDES))


rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
#
#BASH_INCLUDES := $(call rwildcard,$(WWW_PAGES_DIR),*.md)
BASH_SRC := $(abspath $(call rwildcard,$(bin/ext),*.bash)) $(abspath $(wildcard bin/ext/test-more-bash/ext/bashplus/bin/*))
BASH_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(BASH_SRC))
# $(abspath $(wildcard bin/ext/bashplus/lib/*))  \
# $(abspath $(wildcard bin/ext/bashplus/lib/*))

XQ_EXEC := $(abspath bin/xq)
XQ_INCLUDES := $(abspath $(wildcard bin/xq-includes/*))

GH_EXEC := $(abspath bin/gh)
GH_INCLUDES := $(abspath $(wildcard bin/gh-includes/*))

TMX_EXEC := $(abspath bin/tmx)
TMX_INCLUDES := $(abspath $(wildcard bin/tmx-includes/*))

PROPERTIES_SRC :=  $(abspath project.properties common.properties)
PROPERTIES_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(PROPERTIES_SRC))

NODE_SRC :=  $(abspath package.json)
NODE_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(NODE_SRC))

XQ_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(XQ_EXEC) $(XQ_INCLUDES) )
GH_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(GH_EXEC) $(GH_INCLUDES) )
TMX_TARG := $(patsubst $(BASE)/%, $(UP_TARG_DIR)/%, $(TMX_EXEC) $(TMX_INCLUDES) )



define ensure-exec
	@echo 'ensure executable'
	@chmod +x $(1)
endef

#
#build: $(MK_INC_TARG) $(PROPERTIES_TARG)  $(NODE_TARG) $(BASH_TARG) \
#  $(XQ_TARG) $(GH_TARG) $(TMX_TARG) $(WEB_PROJECTS) \
#  $(UP_TARG_DIR)/bin/ext

build:
	@mkdir -p $(UP_TARG_DIR)/bin
	stow -t $(UP_TARG_DIR)/bin bin
	stow -t $(UP_TARG_DIR) properties


clean:
	@rm $(INC_TARG)
	@rm $(gmack)





$(UP_TARG_DIR)/bin/%: $(BASE)/bin/%
	@mkdir -p $(dir $@)
	@echo "MODIFIED: $(@F)"
	@echo "FROM $<"
	@echo "COPY TO $@"
	@mkdir -p $(dir $@)
	@cp $< $@

# Copy over properties file
$(UP_TARG_DIR)/%.properties: $(BASE)/%.properties
	@echo "FILE $@ $<"
	@cp $< $@

# Copy over aliases file
$(HOME)/.%: $(BASE)/.%
	@echo "FILE $@ $<"
	#@cp $< $@

# Copy over aliases file
#$HOME/: bash_aliases
#	@echo "FILE $@ $<"
	#@cp $< $@

$(UP_TARG_DIR)/%.json: $(BASE)/%.json
	@echo "TASK! copy json package into home then install"
	@echo "TARG_DIR $(UP_TARG_DIR)"
	@echo "FILE $@ $<"
	@cp $< $@
	#@cd $(UP_TARG_DIR) && npm install



$(gmack): $(MK)
	@echo "MODIFIED: $(@F)"
	@echo "FROM $<"
	@echo "COPY TO $@"
	@mkdir -p $(dir $@)
	@cp $< $@




