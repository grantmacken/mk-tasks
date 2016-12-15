# github repo TASKS
###############################################################################
#  make issue 
# ISSUE WITH TASK LIST
#  on master:
#  -  make issue:  create a new issue on github
#  -  make branch  create a branch with branch name based on issue 
#  on branch
#   * document changes with issue list
#   * don't push until ready for a pull-request
#   * before push rebase: `git rebase -i @{u}`
#
# PULL REQUEST PHASE
#  - pull-request
#  - gh create-pr-shipit-comment
#  - pr-shipit ... creates a Looks Good To Me shiptit comment
#  - pr-status ... creates a All Good status  
#  - pr-merge
#
#   postMergePackage
#   
#RELEASE
# - release

###############################################################################

ifeq ($(CURRENT_BRANCH),master)
 isMaster = yep
else
 isMaster = $(empty)
endif
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


#############################################################

chkJson = $(shell [ -e $1 ] ||\
 if [ -e $(G)/headers/$(notdir $(basename $1)).txt ];\
 then rm $(G)/headers/$(notdir $(basename $1)).txt; fi;\
 if [ -e $(G)/etags/$(notdir $(basename $1)).etag ];\
 then rm $(G)/etags/$(notdir $(basename $1)).etag ; fi )

repo: $(G)/repo.json

# TODO! incorp  gh default-labels and default milestones
$(G)/repo.json:   config
	@echo "{{{##[ $@ ]##"
	@gh get-repo
	@echo "}}}"

###############################################################################
# ISSUE WITH TASK LIST
#  on master:
#  on branch
#   * don't push until ready for a pull-request
#   * before push rebase: `git rebase -i @{u}`
###############################################################################
#{{{

issue: $(G)/issues.json

branch: $(G)/branch.json


ISSUE.md: $(JSN_REPO)
	@echo "{{{##[ $@ ]##"
	$(if $(isMaster),gh new-issue-md ,)
	$(call chkJson,$@)
	@echo "}}}"

$(G)/issue.json: ISSUE.md
	@echo "{{{##[ $@ ]##"
	$(if $(isMaster),gh create-issue,gh sync-issue)
	$(call chkJson,$@)
	@echo "}}}"
# @echo  "CURRENT_BRANCH:  $(CURRENT_BRANCH)"
# ifneq ($(CURRENT_BRANCH),master)
# @echo "PARSED_ISSUE_NUMBER: $(PARSED_ISSUE_NUMBER)"
# @gh sync-issue
# @gh commit-issue
# @gh get-issue $(PARSED_ISSUE_NUMBER)
# els  # @gh create-issue
# endif

$(G)/issues.json: $(G)/issue.json
	@echo "{{{##[ $@ ]##"
	@$(if $(isMaster),gh get-issues,)
	@$(call chkJson,$@)
	@gh list-issues
	@echo "}}}"

$(G)/branch.json: $(G)/issue.json $(G)/issues.json
	@echo "{{{##[ $@ ]##"
	@echo 'ISSUE_NUMBER: $(shell echo $$(< $(<)) | jq '.number')'
	@echo 'ISSUE_LABEL: $(shell echo $$(< $(<)) | jq '.labels[0]' | jq '.name')'
	@echo 'ISSUE_TITLE: $(shell echo $$(< $(<)) | jq '.title')'
	@echo "$(shell echo $$(< $(<)) | jq '[.labels[0].name ,.number, .title ] | .[] | @sh ' )"
	$(if $(isMaster),gh -v create-branch-from-current-issue,)
	$(call chkJson,$@)
	@echo "}}}"

#}}}

###############################################################################
# PULL REQUEST PHASE
#  - pull-request
#  - gh create-pr-shipit-comment
#  - pr-status
#  - pr-merge
###############################################################################
#{{{

pr:
	@$(MAKE) pull-request
	@$(MAKE) pr-shipit
	@$(MAKE) pr-status
	@$(MAKE) pr-merge
	@$(MAKE) pr-merge


pull-request: $(G)/pr-comments.json

# pr-comment: $(G)/pr-comment.json
# NOTE: do comment stuff manually for now

pr-shipit: $(G)/pr-comment.json

pr-status:  $(G)/pr-combined-status.json  

pr-merge: $(G)/merge.json

$(G)/pull-request.json: $(G)/branch.json
	@echo "{{{##[ $@ ]##"
	@gh create-pull-request
	$(call chkJson,$@)
	@echo "}}}"

$(G)/pr-comments.json:  $(G)/pull-request.json
	@echo "{{{##[ $@ ]##"
	@gh get-pr-comments
	$(call chkJson,$@)
	@echo "}}}"

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
	@echo "{{{##[ $@ ]##"
	@gh get-pr-statuses
	@echo "}}}"

$(G)/pr-status.json: $(G)/pr-statuses.json
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
	@gh create-pr-default-success-status
# 	@echo "------------------------------------------------------------------ "

$(G)/pr-combined-status.json: $(G)/pr-status.json
# 	@echo "##[ $@ ]##"
# 	@echo "whenever we get a new status report fetch the combined status report"
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
	@$(MAKE) pr-merged


postMergeInfo:
	@echo 'post merge info'
	@echo '---------------'
	@gh list-tags
	@echo 'latest tag'
	@gh -v latest-tag

pr-merged: config
	@echo 'post merge build'
	@echo '---------------'
	@echo 'latest tag:       ' $$(gh latest-tag)
	@echo 'latest milestone: ' $$(gh latest-milestone)
	@gh update-semver  $$(gh latest-tag)  $$(gh latest-milestone)
	@sed -i -r "s/^SEMVER=.*/SEMVER=$$(gh update-semver $$(gh latest-tag) $$(gh latest-milestone))/" config
	@$(MAKE) package

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

release: $(G)/release.json

upload: $(G)/tags.json

$(G)/release.json: $(XAR)
	@$(info {{{##[ $@ ]##)
	@$(info create release using following params)
	@$(info tag-name: $(VERSION))
	@$(info name: $(ABBREV)-$(VERSION))
	@$(info body: $(shell echo $$(<$(JSN_PULL_REQUEST)) | jq '.body | @sh'))
	@$(info xar: $(wildcard $(XAR)))
	@gh create-release "v$(VERSION)" "$(ABBREV)-$(VERSION)" "$(shell echo $$(<$(JSN_PULL_REQUEST)) | jq '.body | @sh')"
	@echo "}}}"

$(G)/asset_uploaded.json: $(G)/release.json
	@echo "{{{##[ $@ ]##"
	@echo "tag-name: $(shell echo $$(<$(<)) | jq '.tag_name')"
	@echo "name: $(shell echo $$(<$(<)) | jq '.name')"
	@echo 'upload release using following params'
	@echo "upload-file: $(XAR)"
	@echo "------------------------------------------------------------------ "
	@echo "upload-url:"
	@echo "$$(echo $$(<$(<)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR))"
	@echo "------------------------------------------------------------------ "
	@echo "contentType: $(call getMimeType,$(suffix $(notdir $(XAR))))"
	@gh upload-release-asset \
 "$(XAR)" \
 "$(shell echo \"$$(echo $$(<$(<)) | jq '.upload_url' | sed -r 's/\{.+//g')?name=$(notdir $(XAR)))\")" \
 "$(call getMimeType,$(suffix $(notdir $(XAR))))"
	@echo "}}}"

$(G)/latest-release.json: $(G)/asset_uploaded.json
	@echo "##[ $@ ]##"
	@gh get-latest-release
	@echo "------------------------------------------------------------------ "

$(G)/tags.json: $(G)/latest-release.json
	@echo "##[ $@ ]##"
	@gh get-tags
	@echo 'stash the updated config file'
	@git stash
	@echo 'Pull in tags'
	@git pull --tags
	@echo 'pop back the config file which contains the semver'
	@git stash pop
	@git tag
	@cat config
	@echo "------------------------------------------------------------------ "
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


.PHONY: deploy-local deploy-remote

ifneq ($(wildcard $(G)/latest-release.json),)
releaseTagName != echo $$(<$(G)/latest-release.json) | jq '.tag_name'
releaseName != echo $$(<$(G)/latest-release.json) | jq '.name'
releaseDownloadUrl !=  echo $$(<$(G)/latest-release.json) | jq '.assets[0] | .browser_download_url'
endif

deploy-local:
	@echo "tag-name: $(releaseTagName) "
	@echo "name: $(releaseName)"
	@echo "WEBSITE: $(WEBSITE)"
	@echo "browser_download_url: $(releaseDownloadUrl)"
	@xq -v repo-deploy-local $(WEBSITE) $(releaseDownloadUrl)
	@echo "------------------------------------------------------"

deploy-remote:
	@echo "tag-name: $(releaseTagName) "
	@echo "name: $(releaseName)"
	@echo "WEBSITE: $(WEBSITE)"
	@echo "browser_download_url: $(releaseDownloadUrl)"
	@xq -v repo-deploy-remote $(WEBSITE) $(releaseDownloadUrl)
	@echo "------------------------------------------------------"

# $(JSN_DEPLOYMENT_STATUS): $(JSN_DEPLOYMENT)
#
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
