#==========================================================
#  issues
# working with github issues
#
#==========================================================
# SOURCES
#==========================================================


#==========================================================
# BUILD TARGET PATTERNS
#==========================================================

issue: $(JSN_ISSUE)

#pull-request: $(JSN_PULL_REQUEST) $(JSN_PULLS)

#############################################################
.PHONY: watch-issue

#@watch -q $(MAKE) issue
watch-issue:
	@watch -q $(MAKE) issue

.PHONY:  watch-issue issue-help
#############################################################

issue-help:
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
	@echo "PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)"

$(JSN_ISSUE): $(ISSUE_FILE)
ifneq ($(CURRENT_BRANCH),master)
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
	@echo  "MODIFY: $@"
	@echo "BASENAME: $(basename $(notdir $@))"
	@echo "PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)"
	@gh sync-issue
	@gh commit-issue-task
	@gh get-$(basename $(notdir $@)) $(PARSED_ISSUE_NUMBER)
endif




#$(JSN_PULLS): $(JSN_ISSUE)
#	@echo  "MODIFY $@"
#	@gh get-pulls
#
#$(JSN_PULL_REQUEST):
#	@echo  "MODIFY $@"
#	gh pull-request

#$(JSN_PULL_REQUEST):  $(JSN_ISSUE)
#@echo  "MODIFY $@"

#$(SEMVER_FILE): $(GITHUB_DIR)/issue.json
#	@echo  "MODIFY $@"
#	@echo "BASENAME: $(basename $(notdir $@))"
#	gh semver

#$(XAR): $(SEMVER_FILE)
#	@mkdir -p $(dir $@)
#	@echo "XAR FILE $@"
#	@cd $(BUILD_DIR); zip -r ../$@ .

