SHELL=/bin/bash
include config
include ../common.properties
export PATH := $(abspath ../bin):$(abspath ../node_modules/.bin):$(PATH)
# keep intermediate files
# http://stackoverflow.com/questions/3046117/gnu-makefile-multiple-outputs-from-single-rule-preventing-intermediate-files
.SECONDARY:

# Make sure we have the following apps installed:
APP_LIST = git curl node tidy scour
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this build))
$(foreach src,$(APP_LIST),$(call assert-command-present,$(src)))
# common functions
empty :=
space := $(empty) $(empty)
cat = $(shell if [ -e $(1) ] ;then echo "$$(<$(1))";fi )
rwildcard=$(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
TASKS_DIR := .tasks
include $(TASKS_DIR)/properties.mk
fo := $(TASKS_DIR)/repo.mk $(TASKS_DIR)/properties.mk
include $(filter-out $(fo) ,$(wildcard $(TASKS_DIR)/*.mk))
include $(TASKS_DIR)/repo.mk

default: help

.PHONY: help
