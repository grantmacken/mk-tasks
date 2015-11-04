#==========================================================
#  Build and XAR creation for eXist
#
# 
# 
#
#==========================================================
# SOURCES
#==========================================================
#
SRC_CONFIG := $(CONFIG_FILE)
SRC_SEMVER := $(SEMVER_FILE)
SRC_PKG_XQ := $(shell find $(PKG_DIR) -name '*.xq*')
SRC_PKG_XCONF := $(shell find $(PKG_DIR) -name '*.xconf*')
# SRC_PKG_XML are templates config and semver are pre
# 
SRC_PKG_TMPL := $(PKG_DIR)/repo.xml $(PKG_DIR)/expath-pkg.xml
SRC_PKG_MAIN := $(SRC_PKG_XCONF) $(SRC_PKG_XQ)

#==========================================================
# BUILD TARGET PATTERNS
#==========================================================

PKG_MAIN := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_MAIN))
PKG_TMPL := $(patsubst $(PKG_DIR)/%, $(BUILD_DIR)/%, $(SRC_PKG_TMPL))

#############################################################


ifneq ($(wildcard $(JSN_PULL_REQUEST)),)
PR_MERGED !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.merged'    
PR_TITLE !=  echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.title'    
PR_MILESTONE_TITLE != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .title'    
PR_MILESTONE_DESCRIPTION != echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.milestone | .description'    
endif           

ifneq ($(wildcard $(JSN_TAGS)),)
TAG_LATEST != echo "$$(<$(JSN_TAGS))" | jq -r -c '.[0] | .name '   
endif           

ifneq ($(wildcard $(JSN_RELEASE)),)
RELEASE_UPLOAD_URL != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.upload_url' | sed -r 's/\{.+//g'
RELEASE_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.name'
RELEASE_TAG_NAME != echo "$$(<$(JSN_RELEASE))" | jq -r -c '.tag_name'
endif           

PACKAGE_VERSION != echo "$$(<$(SEMVER_FILE))" | sed 's/v//'
#############################################################
lastTaggedCommit != git rev-list --tags --max-count=1
currentVersionString != git describe --tags $(lastTaggedCommit)
currentVersion != echo "$$( git describe --tags $(lastTaggedCommit) )" | sed 's/v//'
semverMajor !=  cut -d'.' -f1 <<<  $(currentVersion)
semverMinor !=  cut -d'.' -f2 <<<  $(currentVersion)
semverPatch !=  cut -d'.' -f3 <<<  $(currentVersion) 
incSemverPatch != echo v$(semverMajor).$(semverMinor).$$(($(semverPatch) + 1))
incSemverMinor != echo v$(semverMajor).$$(($(semverMinor) + 1)).$(semverPatch)
incSemverMajor != echo v$$(($(semverMajor) + 1)).$(semverMinor).$(semverPatch)

# #  doTask=$(
#   git tag \
#   -a ${RELEASE_NEW_VERSION} \
#   -m '${ISSUE_MILESTONE} based on ${ISSUE_TITLE}'
#   ) 

build: $(SEMVER_FILE) $(PKG_TMPL) $(PKG_MAIN) $(XAR)

.PHONY: watch-build info-build                          

#@watch -q $(MAKE) icons
watch-build:
	@watch -q $(MAKE) build

build-info:
	@echo 'BUILD INFORMATION'
# @echo 'updating all main repo list'
# @echo 'only newer files are updated, checks eTag'
# @gh get-repo-lists
	@echo 'check if last pull request has been merged'
ifeq ($(PR_MERGED),true)
	@echo $(PR_MERGED)   
endif       
	@echo "$(VERSION)"
	@echo 'CURRENT BRANCH'
	@echo $(CURRENT_BRANCH)
	@echo 'REMOTE GH BRANCHES'
	@echo "$$(<$(JSN_BRANCHES))" | jq -r -c '.[] | [ .name ]'    
	@echo 'MILESTONES'
	@echo "$$(<$(JSN_MILESTONES))" | jq -r -c '.[] | [ .title ]'    
	@echo 'LABELS'
	@echo "$$(<$(JSN_LABELS))" | jq -r -c '.[] | [ .name ]'    
	@echo 'TAGS'                                            
	@echo "$$(<$(JSN_TAGS))" | jq -r -c '.[] | [ .name ]'    
	@echo 'ISSUES'                                            
	@echo "$$(<$(JSN_ISSUES))" | jq -r -c '.[] | [ .name ]'    
	@echo 'PULLS'
	@echo "$$(<$(JSN_PULLS))" | jq -r -c '.[] | [ .name ]'    
	@echo 'LAST PULL REQUEST'
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.number'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.state'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.title'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.merged'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.mergeable'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.mergeable_state'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.comments'    
	@echo "$$(<$(JSN_PULL_REQUEST))" | jq -r -c '.commits'    
	@echo 'RELEASES'
	@echo "$$(<$(JSN_RELEASES))" | jq -r -c '.[] | [ .name ]'    
	@echo "LATEST_RELEASE"
	@echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.name'    
	@echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.tag_name'    
	@touch $(JSN_PULL_REQUEST)
	@echo $(lastTaggedCommit)
	@echo $(currentVersionString)
	@echo $(currentVersion)
	@echo $(semverMajor)
	@echo $(semverMinor)
	@echo $(semverPatch) 
ifeq ($(PR_MERGED),true)
	@echo 'whenever the pull request has been merged'
	@echo $(PR_MERGED)   
	@echo 'create a release based on strategy'
	@echo $(PR_MILESTONE_TITLE)
ifeq ($(PR_MILESTONE_TITLE),strategy-major)
	@echo $(incSemverMajor)   
	@echo "$(incSemverMajor)"  > $(SEMVER_FILE)
endif
ifeq ($(PR_MILESTONE_TITLE),strategy-minor)
	@echo 'STRATEGY MINOR'
	@echo $(currentVersion)
	@echo $(incSemverMinor)   
	@echo "$(incSemverMinor)"  > $(SEMVER_FILE)
	@echo '------------------------------------'
endif   
ifeq ($(PR_MILESTONE_TITLE),strategy-patch)
	@echo $(incSemverPatch)   
	@echo "$(incSemverPatch)"  > $(SEMVER_FILE)
endif 
	@echo "$(VERSION)"
endif 

build-release:
	@echo 'BUILD INFORMATION'
	@echo 'check if last pull request has been merged'
ifeq ($(PR_MERGED),true)
	@echo $(PR_MERGED)   
	@echo 'last tagged release'
	@echo $(TAG_LATEST)   
	@echo $(currentVersion) 
	@echo 'next tagged release'
	@echo 'tag-name: $(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo 'body: $(PR_TITLE)  $(PR_MILESTONE_DESCRIPTION) merged into master '
	@gh create-release '$(VERSION)' '$(ABBREV)-$(VERSION)'\
		'$(PR_TITLE) -  $(PR_MILESTONE_DESCRIPTION) merged into master'
endif  

build-asset:
ifeq ($(PR_MERGED),true)
	@echo $(PR_MERGED)   
	@gh get-latest-release 
	@echo $(RELEASE_UPLOAD_URL)
	@echo $(RELEASE_NAME)
	@gh create-release-asset '$(RELEASE_UPLOAD_URL)' '$(RELEASE_NAME)'
endif  


$(SEMVER_FILE): $(JSN_PULL_REQUEST)
	@echo "SEMVER"
	@touch $(JSN_PULL_REQUEST)
ifeq ($(PR_MERGED),true)
	@echo 'whenever the pull request has been merged'
	@echo $(PR_MERGED)   
	@echo 'create a release based on strategy'
	@echo $(PR_MILESTONE_TITLE)
	@echo 'get the latest release tag'
	@echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.tag_name'
	@echo "$$(<$(JSN_LATEST_RELEASE))" | jq -r -c '.tag_name' > $@
	@echo "$$(<$(SEMVER_FILE))"
ifeq ($(PR_MILESTONE_TITLE),strategy-major)
	@echo $(incSemverMajor)   
	@echo $(incSemverMajor)  > $(SEMVER_FILE)
endif 
ifeq ($(PR_MILESTONE_TITLE),strategy-minor)
	@echo $(incSemverMinor)   
	@echo $(incSemverMinor)  > $(SEMVER_FILE)
endif   
ifeq ($(PR_MILESTONE_TITLE),strategy-patch)
	@echo $(incSemverPatch)   
	@echo $(incSemverPatch)  > $(SEMVER_FILE)
endif 
	@echo "$(VERSION)"
endif

# use cheerio as xml parser
$(BUILD_DIR)/repo.xml: $(PKG_DIR)/repo.xml $(CONFIG_FILE) $(SEMVER_FILE)
	@echo  "MODIFY $@"
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

$(BUILD_DIR)/expath-pkg.xml: $(PKG_DIR)/expath-pkg.xml $(CONFIG_FILE)
	@echo  "MODIFY $@"
	@echo  "SRC  $< "
	@node -e "\
 var cheerio = require('cheerio');var fs = require('fs');\
 var x = fs.readFileSync('./$<').toString();\
 var n = cheerio.load(x,{normalizeWhitespace: false,xmlMode: true});\
 n('package').attr('name', '$(REPO)');\
 n('package').attr('abbrev', '$(ABBREV)' );\
 n('package').attr('version', '$(PACKAGE_VERSION)');\
 n('package').attr('spec', '1.0');\
 n('title').text('$(REPO)');\
 require('fs').writeFileSync('./$@', n.xml() )"

# Copy over package root files
$(BUILD_DIR)/%: $(PKG_DIR)/%
	@mkdir -p $(dir $@)
	@echo "FILE $@ $<"
	@cp $< $@

# Create package with zip
# but exclude the data dir
# TODO! might also exclude binary media
$(XAR): $(wildcard $(BUILD_DIR)/* )
	@mkdir -p $(dir $@)
	@echo "XAR FILE $@"
	@cd $(BUILD_DIR); zip -r ../$@ . -x 'data*'
