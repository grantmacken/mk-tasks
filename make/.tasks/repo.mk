
define repoHelp
=========================================================
CURRENT BRANCH: $(CURRENT_BRANCH)

REPO TASKS:

make issue

---------------------------------------------------------
TASKS : make tasks that can be invoked in this repo 

 - make issue

 ISSUE WITH TASK LIST
  on master:
  - make issue: ...  creates a new issue on github
  - make branch ...  creates a branch with branch name based on issue 
  on branch
  - make issue: ...  patch issue

 PULL REQUEST PHASE
  - pull-request
  - pr-shipit ... creates a Looks Good To Me shiptit comment
  - pr-status ... creates a All Good status
  - pr-merge

==========================================================
endef

define issueTemplate
<!--
ISSUE_TITLE='WIP new build'
ISSUE_LABEL='bug'
ISSUE_MILESTONE='patch'
-->
WIP new build

- [ ] dummy task 1
- [ ] dummy task 2

endef

repo-help: export repoHelp:=$(repoHelp)
repo-help:
	@echo "$${repoHelp}"

ifeq ($(CURRENT_BRANCH),master)
 isMaster = yep
else
 isMaster = $(empty)
endif

cleanFetched = $(shell \
 if [ -e $(G)/$(1).json ];then rm $(G)/$(1).json; fi;\
 if [ -e $(G)/headers/$(1).txt ];then rm $(G)/headers/$(1).txt; fi;\
 if [ -e $(G)/etags/$(1).etag ];then rm $(G)/etags/$(1).etag ; fi )

repo: 
	$(MAKE) $(G)/repo.json

# TODO! incorp  gh default-labels and default milestone


$(G)/repo.json:
	@echo "##[ $@ ]##"
	@mkdir -p  $(dir $@)

#######################
# ISSUE WITH TASK LIST

issue:
	@echo "depending on context make or patch issue"
	@gh get-milestones
	@gh get-labels
	@gh get-tags
	@echo "remote tag:   [ $(shell gh latest-tag) ]"
	@gh get-latest-release
	@echo "release tag:  [ $(shell gh latest-release-tag) ]"
	@echo "branch tag:   [ $(shell git describe --abbrev=0 --tags) ]"
	@echo "config semver [ $(SEMVER) ]"
	@$(if $(isMaster),echo 'is on master: [ $(isMaster) ]',echo 'is on master: [ nope! ]')
	@if [[ '$(shell git describe --abbrev=0 --tags)' != '$(shell gh latest-tag)' ]] ;\
 then echo 'local tags need updating';fi
	@$(if $(isMaster),$(MAKE) --silent issue-template,)
	@$(if $(isMaster),$(MAKE) --silent issue-create,)
	@$(if $(isMaster),$(MAKE) --silent branch,)

issue-create:
	@$(if $(isMaster),gh -v create-issue,)

issue-patch: $(G)/issue.json
	@echo "##[ $@ ]##"
	gh get-milestones
	gh get-labels
	@echo 'issue number: [ $(shell cat $<  | jq '.number') ]'
	@echo 'issue url: [ $(shell cat $<  | jq '.url') ]'
	@echo 'milestone number: [ $(shell cat $<  | jq '.milestone.number') ]'
	@gh patch-issue $(shell cat $<  | jq '.number')

.PHONY: issue issue-patch  issue-create branch 

issue-clean:
	@if [ -e issue.md ] ; then rm issue.md; fi
	@$(call cleanFetched,issue)

issue-template: export issueTemplate:=$(issueTemplate)
issue-template:
	@echo "##[ $@ ]##"
	@echo "$${issueTemplate}" > issue.md
	@read -p "enter issue title ➥ " title;\
 sed -i -r "s/^ISSUE_TITLE=.*/ISSUE_TITLE='$$title'/" issue.md;\
 sed -i -r "s/^WIP .*/WIP $$title/" issue.md;
	cat issue.md

branch: $(G)/issue.json
	@echo "##[ $@ ]##"
	@$(if $(isMaster),echo 'is on master: [ $(isMaster) ]',)
	@echo 'ISSUE_NUMBER: $(shell echo $$(< $(<)) | jq '.number')'
	@echo "ISSUE_LABEL: $(shell echo $$(< $(<)) | jq '.milestone.title' )"
	@echo 'ISSUE_TITLE: $(shell echo $$(< $(<)) | jq '.title')'
	@$(if $(isMaster),\
 echo 'will become branch: [ $(shell echo $$(< $(<)) | jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' | sed 's/\s/-/g' )  ] ',)
	$(if $(isMaster),\
 gh -v create-branch-from-current-issue \
 $(shell echo $$(< $(<)) | jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' | sed 's/\s/-/g' ),)
	$(MAKE) --silent branch-tasks

branch-tasks:
	@$(if $(isMaster),$(error  'need to be on a branch'),echo 'new branch tasks')
	@echo "current branch:   [ $(CURRENT_BRANCH) ]"
	@echo "   current tag:   [ $(shell git describe --abbrev=0 --tags | sed s/v// ) ]"
	@echo '    remote tag:   [ $(shell git ls-remote --tags | grep -oP "refs/tags/\K.+" | tail -1 ) ]'
	@echo "   release tag:   [ $(shell gh latest-tag) ]"
	@echo " config semver:   [ $(SEMVER) ]"
	@echo "       version:   [ $(VERSION) ]"
# @echo "new semver [ $(shell gh update-semver $(shell gh latest-tag) $(shell echo $$(< $(<)) | jq '.milestone.title')) ]"
# @if [[ '$(shell gh latest-tag)' = '$(shell git ls-remote --tags | grep -oP "refs/tags/v\K.+" | tail -1 )' ]] ; then\
# echo 'OK! latest release tag same as remote';fi


# @echo "TASK! update config semver for our new build"
# @echo "new semver [ $(shell gh update-semver $(SEMVER) $(shell echo $$(< $(<)) | jq '.milestone.title')) ]"
# @sed -i -r "s/^SEMVER=.*/SEMVER=$(shell gh update-semver $(SEMVER) $(shell echo $$(< $(<)) | jq '.milestone.title'))/" config
# @git push -u origin $(CURRENT_BRANCH)

# @if [[ '$(shell git describe --abbrev=0 --tags)' != '$(shell gh latest-tag)' ]] ;\
# then echo 'local tags need updating';fi
# @if [[ '$(shell git describe --abbrev=0 --tags)' != '$(shell gh latest-tag)' ]] ;\
# then \
# echo 'pull tags from remote';\
# git pull --tags;\
# fi
###############################################################################
# PULL REQUEST PHASE
#  - pull-request
#  - gh create-pr-shipit-comment
#  - pr-status
#  - pr-merge
###############################################################################

pr:
	@$(MAKE) pull-request
	@$(MAKE) pr-shipit
	@$(MAKE) pr-status

.PHONY: pr pull-request 

pr-shipit: $(G)/pr-comment.json

pr-status: $(G)/pr-combined-status.json  

pull-request:
	@echo '## $@ ##'
	@gh create-pull-request
	@echo "-----------------------------------"

$(G)/pr-comments.json:  $(G)/pull-request.json
	@echo "##[ $@ ]##"
	@gh get-pr-comments
	@echo "-------------------------------------"

$(G)/pr-comment.json: $(G)/pr-comments.json
	@echo "{{{##[ $@ ]##"
	@eval $(echo "$$(< $<)" | jq -r '. | length == 0') &&\
 gh create-pr-shipit-comment &&  gh get-pr-comments

# $(if $(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '. | length == 0' | @sh ),true)
# @echo "no comments yet, so create a compare url comment"
# @gh create-pr-compare-url-comment
# else
# ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '.[] | contains({"body":"compare-url"})' ),false)
# @echo "pr comments does not contain a compare url"
# @gh create-pr-compare-url-comment
# else
# @echo "pr comments contains a compare url"
# endif
# ifeq ($(shell echo "$$(<$(JSN_PR_COMMENTS))" | jq '.[] | contains({"body":"shipit"})' ),false)
# @echo "pr comments does not contain a shipit comment"
# @gh create-pr-shipit-comment
# else
# @echo "pr comments contains a shipit comment"
# endif
# endif
	# @echo "}}}"

$(G)/pr-statuses.json: $(G)/pull-request.json
	@echo "##[ $@ ]##"
	@gh get-pr-statuses
	@echo "----------------------------------"

$(G)/pr-status.json: $(G)/pr-statuses.json
	@echo "##[ $@ ]##"
	@gh create-pr-default-success-status
# 	@echo "##[ $on ]##"
# 	@echo "INPUT: $(JSN_PR_STATUSES)"
# 	@echo $(WEBSITE)
# 	@echo "if lints and test OK check OK! create default status for pull request"
# 	@echo "LINTS:[stylelint]( https://github.com/stylelint/stylelint )"
# 	@echo "stylelint will lint src and exit std err on failure"
# 	@stylelint  $(STYLE_SRC_DIR)/* --config $(STYLELINT_CONFIG)
# 	@echo "------------------------------------------------------------------ "
# 	@echo "STYLES:  "
# 	@analyze-css --pretty --url $(WEBSITE)/styles | jq '.metrics' | tee $(LOG_DIR)/analyze-css-metrics.json  | jq '.'
# 	@echo 'prove tap test. test written with tape'
# 	@prove -o  t/analyze-css-metrics.t
# 	@echo "Conditions meet, so create default suucess status "
# 	@echo "------------------------------------------------------------------ "

$(G)/pr-combined-status.json: $(G)/pr-status.json
	@echo "##[ $@ ]##"
	@echo "whenever we get a new status report fetch the combined status report"
	gh get-pr-combined-status
# 	@echo "------------------------------------------------------------------ "

$(G)/merge.json: $(G)/pr-combined-status.json
	@echo "##[ $@ ]##"
	@echo '$(call cat,$<)' | jq '.'
	@echo "if conditions not meet fail. below will eval to true or false "
	@echo 'successful state ' \
 $$( echo '$(call cat,$<)' | jq '.state == "success"')
	@echo 'statuses array with success state' \
 $$( echo '$(call cat,$<)' | jq '.statuses | .[] | contains({"state":"success"})')
	@echo 'statuses with all good description ' \
 $$( echo '$(call cat,$<)' | jq 'contains({statuses: [{"description": "All good"}]})')
	@echo 'both successful state and all good' \
 $$( echo '$(call cat,$<)' | jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))')
	@eval $$( echo '$(call cat,$<)' | jq '.state == "success"')
	@eval $$( echo '$(call cat,$<)' | jq '.statuses | .[] | contains({"state":"success"})')
	@eval $$( echo '$(call cat,$<)' | jq 'contains({statuses: [{"description": "All good"}]})')
	@eval $$( echo '$(call cat,$<)' | jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))')
	@echo "pull request combined status all ready to merge"
	@gh merge-pull-request

merge:
	@make --silent $(G)/merge.json
	@echo 'post merge tasks'
	@echo '---------------'
	@echo ' the pull request should now have a merged true status'
	@echo "pull request url: [ $(shell cat .github/pull-request.json | jq '.url') ]"
	@gh get-pull-request  $(shell cat .github/pull-request.json | jq '.url')
	@echo "pull request merged: [ $(shell cat .github/pull-request.json | jq '.merged') ]"
	@eval $$( cat .github/pull-request.json | jq '(.merged == true)')
	@echo "latest tag: [ $$(gh latest-tag) ]"
	@echo "    semver: [ $(SEMVER) ]" 
	@echo 'latest milestone: ' $$(gh latest-milestone)
	@echo "head ref: [ $(shell cat .github/pull-request.json | jq '.head.ref') ]"
	@echo "checkout master: [ $(shell cat .github/pull-request.json | jq '.base.ref') ]"
	@$(if $(isMaster),,git checkout $(shell cat .github/pull-request.json | jq '.base.ref'))
	@$(MAKE) --silent back-on-master

back-on-master:
	@echo "delete local branch: $(shell cat .github/pull-request.json | jq '.head.ref') "
	@$(if $(isMaster),git branch -D  $(shell cat .github/pull-request.json | jq '.head.ref') ,)
	@echo "delete remote branch: $(shell cat .github/pull-request.json | jq '.head.ref') "
	@$(if $(isMaster),git push origin --delete  $(shell cat .github/pull-request.json | jq '.head.ref') ,)
	@echo "update deploy build "
	@$(MAKE) --silent build

# @if [ -e $(G)/pull-request.json ] ; then rm $(G)/pull-request.json; fi
# @if [ -e $(G)/headers/pull-request.txt ] ; then rm $(G)/headers/pull-request.txt; fi
# @if [ -e $(G)/etags/pull-request.etag ] ; then rm $(G)/etags/pull-request.etag; fi
# @if [ -e $(G)/etags/pull-request.etag ] ; then rm $(G)/etags/pull-request.etag; fi

.PHONY: merged back-to-master


# @gh update-semver  $$(gh latest-tag)  $$(gh latest-milestone)
# @gh update-semver  $$(gh latest-tag)  $$(gh latest-milestone)
# @sed -i -r "s/^SEMVER=.*/SEMVER=$$(gh update-semver $$(gh latest-tag) $$(gh latest-milestone))/" config
# @$(MAKE) build
# @$(MAKE) package
# @$(MAKE) release
# @$(MAKE) upload

# }}}
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
#{{{
###############################################################################

#release: $(G)/tags.json

release: $(G)/latest-release.json

upload: $(G)/asset_uploaded.json

$(G)/latest-release.json: $(XAR)
	@echo '##[ $@ ]##'
	@echo 'create release using following params'
	@echo 'tag-name: v$(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo 'body: $(shell echo $$(<$(G)/pull-request.json) | jq '.body')'
	@echo 'xar: $(wildcard $(XAR))'
	@gh -v create-release 'v$(VERSION)' '$(ABBREV)-$(VERSION)' '$(shell echo $$(<$(G)/pull-request.json) | jq ".body")'
	@echo "------------------------------------------------------------------"

# @gh create-release "v$(VERSION)" "$(ABBREV)-$(VERSION)" "$(shell echo $$(<$(G)/pull-request.json) | jq '.body | @sh')"

$(G)/asset_uploaded.json: $(G)/latest-release.json
	@echo "{{{##[ $@ ]##"
	@echo "tag-name: $(shell echo $$(<$(<)) | jq '.tag_name')"
	@echo "name: $(shell echo $$(<$(<)) | jq '.name')"
	@echo 'upload release using following params'
	@echo "upload-file: $(XAR)"
	@echo "------------------------------------------------------------------ "
	@echo "upload-url:"
	@echo "$$(echo $$(<$(<)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR))"
	@echo "------------------------------------------------------------------ "
	@echo "contentType: application/expath+xar"
	@gh upload-release-asset \
 "$(XAR)" \
 "$(shell echo \"$$(echo $$(<$(<)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR)))\")" \
 "application/expath+xar"
	@gh get-latest-release
	@echo "}}}"

# $(G)/tags.json: $(G)/latest-release.json
# @echo "##[ $@ ]##"
# @gh get-tags
# @echo 'stash the updated config file'
# @git stash
# @echo 'Pull in tags'
# @git pull --tags
# @echo "------------------------------------------------------------------ "

tag-semver-sync:
	@sed -i -r "s/^SEMVER=.*/SEMVER=$$(gh latest-tag)/" config
	@cat config
	@$(if $(shell gh latest-tag),\
 $(shell sed -i -r "s/^SEMVER=.*/SEMVER=$$(gh latest-tag)/" config) ,\
 $(info  no latest tag))
	@echo "}}}"


# @echo 'pop back the config file which contains the semver'
# @git stash pop
# @git tag
# @cat config
# @gh update-semver $$(gh latest-tag) $$(gh latest-milestone)
# @gh latest-milestone
#}}}
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
#{{{
###############################################################################
# @xq -v repo-deploy-local \
	#  NY
#  "$(WEBSITE)" \
#  "$(shell echo $$(<) |\
#  jq '.assets[0] | .browser_download_url' )"

.PHONY: deploy  

ifneq ($(wildcard $(G)/latest-release.json),)
releaseTagName != echo $$(<$(G)/latest-release.json) | jq '.tag_name'
releaseName != echo $$(<$(G)/latest-release.json) | jq '.name'
releaseDownloadUrl !=  echo $$(<$(G)/latest-release.json) | jq '.assets[0] | .browser_download_url'
endif

repoDeploy:
	@gh -v get-latest-release
	@echo "download url: [ $(shell gh info-asset-download-url ) ]"
	@echo "release tag name [ $(shell gh info-release-tag-name) ]"
	@echo "download count: [ $(shell gh info-asset-download-count ) ]"
	@echo "download count: [ $(shell gh info-asset-download-count ) ]"
	@echo "$(shell xQdeploy install && xQdeploy list)"
	@gh get-latest-release
	@echo "download count: [ $(shell gh info-asset-download-count ) ]"
	@echo "------------------------------------------------------"

# xQdeploy -v

repoDeployVerbose:
	@gh get-latest-release
	@xQdeploy -v
	@echo "------------------------------------------------------"

repoUndeploy:
	@gh get-latest-release
	@xQdeploy undeploy
	@echo "------------------------------------------------------"


# @echo "tag-name: $(releaseTagName) "
# @echo "name: $(releaseName)"
# @echo "WEBSITE: $(WEBSITE)"
# @echo "browser_download_url: $(releaseDownloadUrl)"
# $(JSN_DEPLOYMENT_STATUS): $(JSN_DEPLOYMENT)
#
# @xq -v repo-deploy-local $(WEBSITE) $(releaseDownloadUrl)
# @xq -v repo-deploy-local $(WEBSITE) $(releaseDownloadUrl)
# 	@gh create-deployment "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.tag_name')"
# 	@echo "##[ $@ ]##"
# 	@echo  "after localhost tests create default success status"
# 	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)"
# 	@gh create-deployment-status '$(DEPLOYMENT_ID)' 'success'
# 	echo "------------------------------------------------------------------ "

# $(JSN_DEPLOYMENT_STATUSES): $(JSN_DEPLOYMENT_STATUS)
# 	@echo "{{{##[ $@ ]##"
# 	@echo "DEPLOYMENT_ID: $(DEPLOYMENT_ID)"
# 	@gh get-deployment-statuses '$(DEPLOYMENT_ID)'
# 	@xq -r  install-and-deploy  "$(NAME)" "$(shell echo $$(<$(JSN_LATEST_RELEASE)) | jq '.assets[0] | .browser_download_url' )"
# 	echo "}}}"

###}}}
