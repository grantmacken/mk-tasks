#==========================================================
ifneq ($(wildcard $(JSN_ISSUE)),)
 ISSUE_NUMBER !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.number'
 ISSUE_TITLE !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.title'
 ISSUE_LABEL !=  echo "$$(<$(JSN_ISSUE))" | jq -r -c '.labels[0] | .name'
 ISSUE_NAME = $(subst $(space),-,$(ISSUE_LABEL) $(ISSUE_NUMBER) $(ISSUE_TITLE))
endif

ifneq ($(wildcard $(JSN_PULL_REQUEST)),)
 PR_MERGED !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.merged'    
 PR_TITLE !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.title'    
 PR_MILESTONE_TITLE != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .title'    
 PR_MILESTONE_DESCRIPTION != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .description'    
 PR_HEAD_REFERENCE  != echo $$(<$(JSN_PULL_REQUEST)) | jq '.head | .ref'
 PR_BODY !=  echo $$(<$(JSN_PULL_REQUEST)) | jq '.body | @sh'
endif           

# BUILD TARGET PATTERNS
#==========================================================

SRC_PKG_XQ := $(shell find $(PKG_DIR) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(PKG_DIR) -name '*.xconf*')
SRC_PKG_TMPL := $(PKG_DIR)/repo.xml $(PKG_DIR)/expath-pkg.xml
SRC_PKG_MAIN := $(SRC_PKG_XCONF) $(SRC_PKG_XQ)
PKG_MAIN := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_MAIN))
PKG_TEMPLATES := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_TMPL))

#############################################################

REPO_LISTS := tags milestones branches
PR_LISTS := commits comments statuses

pr-lists := $(addsuffix .json,$(addprefix $(GITHUB_DIR)/, $(PR_LISTS) ))
#==========================================================
# BUILD TARGET PATTERNS
#==========================================================
repo: $(addsuffix .json,$(addprefix $(GITHUB_DIR)/,tags milestones branches))

#############################################################
# @gh get-$(basename $(notdir $@))
#############################################################

$(addsuffix .json,$(addprefix $(GITHUB_DIR)/,tags milestones branches)): ${CONFIG_FILE}
	@echo "##[ $@ ]##"
	@echo 'SRC: $<'
	@echo "basename: $(basename $(notdir $@))"
	gh get-$(basename $(notdir $@))
	@echo '-------------------------------------------------------------------'


###############################################################################
# ISSUE WITH TASK LIST
#  on master:
#  on branch
#   * don't push until ready for a pull-request
#   * before push rebase: `git rebase -i @{u}`
###############################################################################

issue: $(JSN_ISSUES) $(ISSUE_FILE) $(JSN_ISSUE) $(JSN_BRANCH)

$(JSN_ISSUES): $(JSN_REPO)
	@echo "##[ $@ ]##"
ifeq ($(CURRENT_BRANCH),master)
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
	@gh get-issues
endif
	@echo "------------------------------------------------------------------ "

$(ISSUE_FILE): $(JSN_ISSUES)
	@echo "##[ $@ ]##"
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
ifeq ($(CURRENT_BRANCH),master)
	@echo "only when on master create a new issue-md"
	@gh new-issue-md
else
	@echo "when on branch"
endif
	@echo "------------------------------------------------------------------ "

$(JSN_ISSUE): $(ISSUE_FILE)
	@echo "##[ $@ ]##"
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
ifneq ($(CURRENT_BRANCH),master)
	@echo "PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)"
	@gh sync-issue
	@gh commit-issue
	@gh get-issue $(PARSED_ISSUE_NUMBER)
else
	@gh create-issue
endif
	@echo "------------------------------------------------------------------ "

$(JSN_BRANCH): $(JSN_ISSUE)
	@echo "##[ $@ ]##"
	@echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
	@echo "ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)"
	@echo "ISSUE_LABEL: $(PARSED_ISSUE_LABEL)"
	@echo "ISSUE_TITLE: $(PARSED_ISSUE_TITLE)"
	@echo "ISSUE_NAME: $(ISSUE_NAME)"
ifeq ($(CURRENT_BRANCH),master)
	@echo "only when on master create branch based on issue"
	@gh create-branch-from-issue
	@gh get-branch "$(subst $(space),-,$(ISSUE_LABEL) $(ISSUE_NUMBER) $(ISSUE_TITLE))"
else
	@echo "when on  branch"
	@echo "ISSUE_NUMBER: $(ISSUE_NUMBER)"
	gh get-branch "$(ISSUE_NAME)"
	#touch $(@)
endif
	@echo "------------------------------------------------------------------ "

###############################################################################
# PULL REQUEST PHASE

pull-request: $(JSN_PULL_REQUEST) $(JSN_PR_COMMENTS)

pr-comment: $(JSN_PR_COMMENT)

pr-status:  $(JSN_PR_STATUSES)  $(JSN_PR_STATUS) $(JSN_PR_COMBINED_STATUS)

pr-merge: $(JSN_MERGE)

$(JSN_PULL_REQUEST): $(JSN_BRANCH)
	@echo "##[ $@ ]##"
	@gh create-pull-request
	@echo "------------------------------------------------------------------ "

$(JSN_PR_COMMENTS): $(JSN_PULL_REQUEST)
	@echo "##[ $@ ]##"
ifneq ($(PR_MERGED),true)
	@gh get-pr-comments
endif
	@echo "------------------------------------------------------------------ "

$(JSN_PR_STATUSES): $(JSN_PULL_REQUEST)
	@echo "##[ $@ ]##"
ifneq ($(PR_MERGED),true)
	@gh get-pr-statuses
endif
	@echo "------------------------------------------------------------------ "

$(JSN_PR_COMMENT): $(JSN_PR_COMMENTS)
	@echo "##[ $@ ]##"
	@echo "INPUT: $(JSN_PR_COMMENTS)"
	@echo "upon meeting conditions create comment for pull request"
ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '. | length == 0'),true)
	@echo "no comments yet, so create a compare url comment"
	@gh create-pr-compare-url-comment
else
 ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '.[] | contains({"body":"compare-url"})' ),false)
	@echo "pr comments does not contain a compare url"
	@gh create-pr-compare-url-comment
 else
	@echo "pr comments contains a compare url"
 endif
 ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '.[] | contains({"body":"shipit"})' ),false)
	@echo "pr comments does not contain a shipit comment"
	@gh create-pr-shipit-comment
 else
	@echo "pr comments contains a shipit comment"
 endif
endif
	@echo "------------------------------------------------------------------ "

$(JSN_PR_STATUS): $(JSN_PR_STATUSES)
	@echo "##[ $@ ]##"
	@echo "INPUT: $(JSN_PR_STATUSES)"
	@echo $(WEBSITE)
	@echo "if lints and test OK check OK! create default status for pull request"
	@echo "LINTS:[stylelint]( https://github.com/stylelint/stylelint )"
	@echo "stylelint will lint src and exit std err on failure"
	@stylelint  $(STYLE_SRC_DIR)/* --config $(STYLELINT_CONFIG)
	@echo "------------------------------------------------------------------ "
	@echo "STYLES:  "
	@analyze-css --pretty --url $(WEBSITE)/styles | jq '.metrics' | tee $(LOG_DIR)/analyze-css-metrics.json  | jq '.'
	@echo 'prove tap test. test written with tape'
	@prove -o  t/analyze-css-metrics.t
	@echo "Conditions meet, so create default suucess status "
	gh create-pr-default-success-status
	@echo "------------------------------------------------------------------ "

$(JSN_PR_COMBINED_STATUS): $(JSN_PR_STATUS)
	@echo "##[ $@ ]##"
	@echo "whenever we get a new status report fetch the combined status report"
	gh get-pr-combined-status
	@echo "------------------------------------------------------------------ "

$(JSN_MERGE): $(JSN_PR_COMBINED_STATUS) 
	@echo "##[ $@ ]##"
	@echo "upon meeting conditions create release"
	@echo "$$(<$<)" | jq '.state == "success"'
	@echo "$$(<$<)" | jq '.total_count == 2'
	@echo "$$(<$<)" | jq '.statuses | .[] | contains({"state":"success"})'
	@echo "$$(<$<)" | jq 'contains({statuses: [{"description": "All good"}]})'
	@echo "$$(<$<)" | jq '(.state == "success") and (contains({statuses: [{"description": "All  good"}]}))'
ifeq ($(shell echo $$(<$(JSN_PR_COMBINED_STATUS)) | jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))'),true)
	@echo "pull request combined status all ready to merge"
	@gh merge-pull-request
endif
	@echo "------------------------------------------------------------------ "

###############################################################################
# BUILD PHASE
# pull request merged and now on master:
# update semver TODO! discuss how this is done
# update config
# interpolation 'semver and config' vars into template and place in build
# copy over other changed package files into build
# everything else (templates, modules , resources ) should be already there
# update xar  TODO! might have to recurse to update version
#   $(CONFIG_FILE) $(PKG_TEMPLATES) $(PKG_MAIN) $(XAR)
#
# @gh update-semver
###############################################################################

build: $(SEMVER_FILE) $(CONFIG_FILE) $(PKG_TEMPLATES) $(PKG_MAIN)  $(XAR)

$(SEMVER_FILE): $(JSN_MERGE)
	@echo "##[ $@ ]##"
	@echo "upon merge create a new semver file for release"
ifeq ($(PR_MERGED),true)
	@echo  $(PR_MERGED)
	@echo  $(PR_MILESTONE_TITLE)
	@gh update-semver "$$(xq -r app-semver | sed 's/v//' )" "$(PR_MILESTONE_TITLE)" | tee  $@
endif

$(CONFIG_FILE): $(SEMVER_FILE)
	@echo "##[ $@ ]##"
	@echo "whenever semver changes touch config so we get a fresh build"
	@echo "$$(<$@)"
	@touch $@
	@echo "------------------------------------------------------------------ "

# use cheerio as xml parser
$(BUILD_DIR)/repo.xml: $(PKG_DIR)/repo.xml $(CONFIG_FILE)
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('description').text('$(DESCRIPTION)');\
 n('author').text('$(AUTHOR)');\
 n('website').text('$(WEBSITE)');\
 n('target').text('$(NAME)');\
 require('fs').writeFileSync('./$@', n.xml() )"
	@echo "------------------------------------------------------------------ "

$(BUILD_DIR)/expath-pkg.xml: $(PKG_DIR)/expath-pkg.xml $(CONFIG_FILE)
	@echo  "MODIFY $@"
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('package').attr('name', '$(WEBSITE)');\
 n('package').attr('abbrev', '$(ABBREV)');\
 n('package').attr('version', '$(VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(NAME)');\
 require('fs').writeFileSync('./$@', n.xml() )"
	@echo "------------------------------------------------------------------ "


# Copy over package root files
$(BUILD_DIR)/%: $(PKG_DIR)/%
	@mkdir -p $(dir $@)
	@echo "FILE $@ $<"
	@cp $< $@
	@echo "------------------------------------------------------------------ "

# Create package with zip
# but exclude the data dir
# TODO! might also exclude binary media
$(XAR): $(wildcard $(BUILD_DIR)/* )
	@echo "##[ $@ ]##"
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(BUILD_DIR); zip -r ../$@ . -x 'data*'
	@echo "------------------------------------------------------------------ "

test-packaging:
	@echo 'TEST PACKAGING'
	@prove t/packaging.t
	@echo "------------------------------------------------------------------ "

PHONY: test-packaging
###############################################################################
# RELEASE and main release asset
#
#  release asset is deployable zipped xar from build
#  contains modules, templates and resources
#  excludes data   TODO! might also exclude media content. i.e.
#   images video
#
# create-release params=(tag_name name body)
#  auto included target_commitish:master
#  included defaults  draft:false and prerelease:false
#
#  upload-release-asset  params=( uploadFile uploadURL contentType )
#
###############################################################################

release: $(JSN_RELEASE) $(JSN_ASSET_UPLOADED) $(JSN_LATEST_RELEASE)

$(JSN_RELEASE): $(XAR)
	@echo "##[ $@ ]##"
	@echo 'create release using following params'
	@echo 'tag-name: $(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo "body: $(PR_BODY)"
	@echo $(wildcard $(XAR))
	@gh create-release "v$(VERSION)" "$(ABBREV)-$(VERSION)" "$(PR_BODY)"
	@echo "------------------------------------------------------------------ "

$(JSN_ASSET_UPLOADED): $(JSN_RELEASE)
	@echo "##[ $@ ]##"
	@echo "tag-name: $(shell echo $$(<$(JSN_RELEASE)) | jq '.tag_name')"
	@echo "name: $(shell echo $$(<$(JSN_RELEASE)) | jq '.name')"
	@echo 'upload release using following params'
	@echo "upload-file: $(XAR)"
	@echo "------------------------------------------------------------------ "
	@echo "upload-url:"
	@echo "$$(echo $$(<$(JSN_RELEASE)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR))"
	@echo "------------------------------------------------------------------ "
	@echo "contentType: $(call getMimeType,$(suffix $(notdir $(XAR))))"
	@gh upload-release-asset \
 "$(XAR)" \
 "$(shell echo \"$$(echo $$(<$(JSN_RELEASE)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR)))\")" \
 "$(call getMimeType,$(suffix $(notdir $(XAR))))"
	@echo "------------------------------------------------------------------ "

$(JSN_LATEST_RELEASE): $(JSN_ASSET_UPLOADED)
	@echo "##[ $@ ]##"
	@gh get-latest-release
	@echo "------------------------------------------------------------------ "


###############################################################################
# DEPLOYMENTo
#  create a github deployment with conditional contexts
#  "required_contexts": [
#      "tap/common"
#      ]
#  deploy and install to localhost
#  run any available localhost tap tests
#  if OK!
#  create a Deployment status
#
# @echo "------------------------------------------------------------------ "
# @echo "PERFORMANCE: "
# @phantomas $(WEBSITE) --runs 5
# @phantomas $(WEBSITE) --config=$(PHANTOMAS_CONFIG) --analyze-css | faucet
# @echo "ACCESSABILITY: pa11y accessability tests https://github.com/nature/pa11y "
# @pa11y $(WEBSITE) --level none --standard WCAG2A
# @echo "------------------------------------------------------------------ "
# $(JSN_DEPLOYMENT) $(JSN_DEPLOYMENT_STATUS) $(JSN_DEPLOYMENT_STATUSES)
###############################################################################

deploy:  .logs/xq/install-and-deploy.log

$(LOG_DIR)/xq/install-and-deploy.log: $(JSN_LATEST_RELEASE)
	@echo "##[ $@ ]##"
	@echo $(basename $(notdir $@))
	@echo "tag-name: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.tag_name')"
	@echo "name: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.name')"
	@echo "WEBSITE: $(WEBSITE)"
	@echo "browser_download_url: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
	@xq -v install-and-deploy "$(WEBSITE)" "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
	echo "------------------------------------------------------------------ "

$(JSN_DEPLOYMENT):
	@echo "##[ $@ ]##"
	@echo  'deployment to localhost first'
	@echo "tag-name: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.tag_name')"
	@echo "name: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.name')"
	@echo "browser_download_url: $(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
	@xq install-and-deploy  "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
	echo "------------------------------------------------------------------ "

$(JSN_DEPLOYMENT_STATUS): $(JSN_DEPLOYMENT)
	@gh create-deployment "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.tag_name')"
	@echo "##[ $@ ]##"
	@echo  "after localhost tests create default success status"
	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)"
	@gh create-deployment-status '$(DEPLOYMENT_ID)' 'success'
	echo "------------------------------------------------------------------ "

$(JSN_DEPLOYMENT_STATUSES): $(JSN_DEPLOYMENT_STATUS)
	@echo "##[ $@ ]##"
	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)"
	@gh get-deployment-statuses '$(DEPLOYMENT_ID)'
	@xq -r  install-and-deploy  "$(NAME)" "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
	echo "------------------------------------------------------------------ "
