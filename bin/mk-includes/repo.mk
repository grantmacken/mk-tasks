#==========================================================
# repo.mk
# working with github repo
#
#==========================================================
# SOURCES
#==========================================================
#SRC_JSON := $(shell find $(GITHUB_DIR) -name '*.json')
#==========================================================
# BUILD TARGET PATTERNS
#==========================================================
#ETAGS_GITHUB := $(patsubst $(GITHUB_DIR)/%.json, $(GITHUB_DIR)/etags/%.etag, $(SRC_JSON))
# GITHUB_REPO

GH_REPO := $(GITHUB_DIR)/repo.json
SRC_REPO_LISTS := tags milestones branches issues pulls releases
GH_REPO_LISTS := $(patsubst %, $(GITHUB_DIR)/%.json, $(SRC_REPO_LISTS))

repo: $(GH_REPO) $(GH_REPO_LISTS)


#############################################################
##@watch -q $(MAKE) repo
watch-repo:
	@watch -q $(MAKE) repo
#
.PHONY: watch-repo

#############################################################

$(GH_REPO): $(CONFIG_FILE)
	@echo  "MODIFY $@"
	@echo  "SRC $<"
	gh get-repo
	gh parse-repo
#touch $@

$(GH_REPO_LISTS): $(GH_REPO)
	@echo  "MODIFY $@"
	@echo "basename: $(basename $(notdir $@))"
	@gh get-$(basename $(notdir $@))



#ifneq ($(CURRENT_BRANCH),master)
#
#endif
##gh get-$(basename $(notdir $@)) $(PARSED_ISSUE_NUMBER)
