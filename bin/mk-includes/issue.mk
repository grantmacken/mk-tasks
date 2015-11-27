#==========================================================
SRC_PKG_XQ := $(shell find $(PKG_DIR) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(PKG_DIR) -name '*.xconf*')
SRC_PKG_TMPL := $(PKG_DIR)/repo.xml $(PKG_DIR)/expath-pkg.xml
SRC_PKG_MAIN := $(SRC_PKG_XCONF) $(SRC_PKG_XQ)

#==========================================================
# BUILD TARGET PATTERNS
#==========================================================

PKG_MAIN := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_MAIN))
PKG_TEMPLATES := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_TMPL))

#############################################################

#  issues
# working with github issues
#
#==========================================================
# SOURCES
#==========================================================

PR_LISTS := commits comments statuses

# combined-status
#==========================================================
# BUILD TARGET PATTERNS
#==========================================================
# pr-lists: $(addsuffix .json,$(addprefix $(GITHUB_DIR)/, $(PR_LISTS) ))

issue-sync: $(JSN_ISSUE)

pull-request: $(JSN_PULL_REQUEST)

pr-comment: $(JSN_PR_COMMENT)

pr-merge: $(JSN_MERGE)

pr-build: $(SEMVER_FILE) $(CONFIG_FILE) $(PKG_TEMPLATES) $(PKG_MAIN) $(XAR)

pr-release: $(JSN_RELEASE)  $(JSN_ASSET_UPLOADED) $(JSN_LATEST_RELEASE)

pr-deploy: $(JSN_DEPLOYMENT)  $(JSN_DEPLOYMENT_STATUS) $(JSN_DEPLOYMENT_STATUSES) 

#############################################################
.PHONY: watch-issue

#@watch -q $(MAKE) issue
watch-issue:
	@watch -q $(MAKE) issue

.PHONY:  watch-issue issue-help
#############################################################

# @phantomas $(WEBSITE) --analyze-css --har=$(LOG_DIR)/har.json --format=tap | faucet
# @yslow-node -v -d -f plain -i all -r yblog $(LOG_DIR)/har.json
#STATUS_COUNT = $(eval STATUS_COUNT := $(shell [[ "$$( echo $$(<$$(JSN_PR_COMBINED_STATUS)) | jq '.total_count == 3')" == "false" ]] && echo 'yep' || echo 'nope' ))$(STATUS_COUNT)

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

$(JSN_PULL_REQUEST): $(JSN_ISSUE)
	@gh create-pull-request

# $(GITHUB_DIR)/%.json: $(JSN_PULL_REQUEST)
# 	@echo "##[ $@ ]##"
# 	@echo "github dir: $(GITHUB_DIR)"
# 	@echo "pr lists: $(PR_LISTS)"
# 	@echo "stem:   $* "
# 	@gh get-pr-$*
# 	@echo "------------------------------------------------------------------ "

# statusCountOk = $(shell echo "$$( echo $$(<$1) | jq '.total_count == 3')" ) 

$(JSN_PR_COMMENT): $(JSN_PR_COMMENTS)
	@echo "##[ $@ ]##"
	@echo "INPUT: $(JSN_PR_COMMENTS)"
	@echo "upon meeting conditions create comment for pull request"
ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '. | length == 0'),true)
	@echo "no comments yet, so create a compare url comment"
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
	@echo "STYLES: [analyze-css](  )  "      
	@analyze-css --pretty --url $(WEBSITE)/styles | jq '.metrics' | tee $(LOG_DIR)/analyze-css-metrics.json  | jq '.'
	@echo 'prove tap test. test written with tape'
	@prove -o  t/analyze-css-metrics.t
	@echo "------------------------------------------------------------------ "
	@echo "PERFORMANCE: "      
	@phantomas $(WEBSITE) --runs 5
	@phantomas $(WEBSITE) --config=$(PHANTOMAS_CONFIG) --analyze-css | faucet
	@echo "ACCESSABILITY: pa11y accessability tests https://github.com/nature/pa11y "  
	@pa11y $(WEBSITE) --level none --standard WCAG2A
	@echo "------------------------------------------------------------------ "
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
#
###############################################################################

$(SEMVER_FILE): $(JSN_MERGE) 
	@echo "##[ $@ ]##"
	@echo "upon meeting conditions create a new semver file for release"
	@echo "$$(<$<)" | jq '.'
	@gh update-semver
	@touch $(@)
	@echo "------------------------------------------------------------------ "   

$(CONFIG_FILE): $(SEMVER_FILE) 
	@echo "##[ $@ ]##"
	@echo "whenever semver changes touch config so we get a fresh build"
	@echo "$$(<$@)"
	@touch $@
	@echo "------------------------------------------------------------------ "   

# use cheerio as xml parser
$(BUILD_DIR)/repo.xml: $(PKG_DIR)/repo.xml $(CONFIG_FILE) $(SEMVER_FILE)
	@echo  "MODIFY $@"
	@echo "##[ $@ ]##"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('description').text('$(DESCRIPTION)');\
 n('author').text('$(AUTHOR)');\
 n('website').text('$(WEBSITE)');\
 n('target').text('$(REPO)');\
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
 n('package').attr('name', '$(REPO)');\
 n('package').attr('abbrev', '$(ABBREV)' );\
 n('package').attr('version', '$(VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(REPO)');\
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
###############################################################################

ifneq ($(wildcard $(JSN_PULL_REQUEST)),)
PR_MERGED !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.merged'    
PR_TITLE !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.title'    
PR_MILESTONE_TITLE != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .title'    
PR_MILESTONE_DESCRIPTION != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .description'    
PR_HEAD_REFERENCE  != echo $$(<$(JSN_PULL_REQUEST)) | jq '.head | .ref'
PR_BODY !=  echo $$(<$(JSN_PULL_REQUEST)) | jq '.body | @sh'
endif           

ifneq ($(wildcard $(JSN_RELEASE)),)
UPLOAD_URL != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.upload_url' | sed -r 's/\{.+//g'
RELEASE_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.name'
RELEASE_TAG_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.tag_name'
RELEASE_UPLOAD_FILE != echo "$(PKG_XAR_DIR)/${RELEASE_NAME}.xar"
RELEASE_UPLOAD_URL != echo "$(UPLOAD_URL)?name=${RELEASE_NAME}.xar&label=${RELEASE_NAME}"
endif           

ifneq ($(wildcard $(JSN_LATEST_RELEASE)),)
TAG_NAME != echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.tag_name'
BROWSER_DOWNLOAD_URL != echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.assets[0] | .browser_download_url'
endif           

ifneq ($(wildcard $(JSN_DEPLOYMENT)),)
DEPLOYMENT_ID != echo "$$(<$(JSN_DEPLOYMENT))" | jq -r -c '.id'
endif           

$(JSN_RELEASE): $(XAR)
	@echo "##[ $@ ]##"
	@echo 'create release using following params'
	@echo 'tag-name: $(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo "body: $(PR_BODY)" 
	@gh create-release "$(VERSION)" "$(ABBREV)-$(VERSION)" "$(PR_BODY)"
	@echo "------------------------------------------------------------------ "   

$(JSN_ASSET_UPLOADED): $(JSN_RELEASE)
	@echo "##[ $@ ]##"
	@echo 'tag-name: $(RELEASE_TAG_NAME)'
	@echo 'name: $(RELEASE_NAME)'
	@echo "upload-file: $(RELEASE_UPLOAD_FILE)"            
	@echo "upload-url: $(RELEASE_UPLOAD_URL)" 
ifneq ($(wildcard $(RELEASE_UPLOAD_FILE)),)
	@echo "contentType: $(call getMimeType,$(suffix $(notdir $(RELEASE_UPLOAD_FILE))))"               
	@gh upload-release-asset \
 "$(RELEASE_UPLOAD_FILE)" \
 "$(RELEASE_UPLOAD_URL)" \
 "$(call getMimeType,$(suffix $(notdir $(RELEASE_UPLOAD_FILE))))"
endif           
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
###############################################################################

$(JSN_DEPLOYMENT): $(JSN_LATEST_RELEASE)
	@echo "##[ $@ ]##"
	@echo  deployment to localhost first'    
	@echo 'BROWSER_DOWNLOAD_URL: $(BROWSER_DOWNLOAD_URL)'
	@echo "TAG_NAME: $(TAG_NAME)" 
	@xq install-and-deploy
	@gh create-deployment '$(TAG_NAME)'
	echo "------------------------------------------------------------------ "   

$(JSN_DEPLOYMENT_STATUS): $(JSN_DEPLOYMENT)
	@echo "##[ $@ ]##"
	@echo  "after localhost tests create default success status"    
	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)" 
	@gh create-deployment-status '$(DEPLOYMENT_ID)' 'success'
	echo "------------------------------------------------------------------ "   

$(JSN_DEPLOYMENT_STATUSES): $(JSN_DEPLOYMENT_STATUS)
	@echo "##[ $@ ]##"
	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)" 
	@gh get-deployment-statuses '$(DEPLOYMENT_ID)'
	echo "------------------------------------------------------------------ "   
