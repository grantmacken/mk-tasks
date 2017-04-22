
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
  - make issue-patch: ...  patch issue

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

issue: issue.json

issue-prior:
	@echo "## $@ ##"
	@echo "update repo info"
	@gh get-repo
	@gh get-milestones
	@gh get-labels
	@gh get-tags
	@echo "remote tag:   [ $(shell gh latest-tag) ]"
	@gh get-latest-release
	@echo "release tag:  [ $(shell gh latest-release-tag) ]"
	@echo "local tag:   [ $(shell git describe --abbrev=0 --tags) ]"
	@echo "config semver [ $(SEMVER) ]"
	@$(if $(isMaster),,echo 'is on master: [ $(isMaster) ]',echo 'is on master: [ nope! ]')
	@if [[ '$(shell git describe --abbrev=0 --tags)' != '$(shell gh latest-tag)' ]] ;\
 then echo 'local tags need updating';fi
	@$(if $(isMaster),echo 'is on master: [ $(isMaster) ]',echo 'is on master: [ nope! ]')
	@$(MAKE) --silent issue-clean

issue-clean:
	@if [ -e issue.md ] ; then rm issue.md; fi
	@$(call cleanFetched,issue)
	@$(call cleanFetched,branch)

issue.md: export issueTemplate:=$(issueTemplate)
issue.md:
	@echo "##[ $@ ]##"
	@$(MAKE) --silent issue-prior
	@echo "$${issueTemplate}" > $@
	@read -p "enter issue title ➥ " title;\
 sed -i -r "s/^ISSUE_TITLE=.*/ISSUE_TITLE='$$title'/" $@;\
 sed -i -r "s/^WIP .*/WIP $$title/" $@;
	@cat $@

issue.json: issue.md
	@echo "##[ $@ ]##"
	@gh create-issue
	@echo 'issue number: [ $(shell jq '.number' $@ ) ]'
	@echo 'issue url: [ $(shell jq '.url' $@ ) ]'
	@echo 'milestone number: [ $(shell jq '.milestone.number' $@ ) ]'

branch:
	@echo "##[ $@ ]##"
	@$(MAKE) --silent $(G)/branch.json
	@$(MAKE) --silent branch-tasks

issue-patch: $(G)/issue.json
	@echo "##[ $@ ]##"
	@echo 'issue number: [ $(shell jq '.number' $< ) ]'
	@echo 'issue url: [ $(shell jq '.url' $< ) ]'
	@echo 'milestone number: [ $(shell jq '.milestone.number' $< ) ]'
	@gh patch-issue $(shell jq '.number' $< )

.PHONY: issue issue-patch branch 

$(G)/branch.json: $(G)/issue.json
	@echo "##[ $@ ]##"
	@$(if $(isMaster),echo 'is on master: [ $(isMaster) ]', false)
	@echo 'ISSUE_NUMBER: $(shell jq '.number' $< )'
	@echo "ISSUE_LABEL: $(shell jq '.milestone.title' $< )"
	@echo 'ISSUE_TITLE: $(shell jq '.title' $< )'
	@echo 'ISSUE_TITLE: $(shell jq '.title' $< )'
	@echo '$(shell git branch | grep -oP master)' 
	@git branch | grep -q $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g') && \
 echo 'ERROR! branch already exists'; false || \
 echo 'will become branch: [ $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g')  ]'
	@git checkout -b $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g')  origin/master
	@git push
	@gh get-branch $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g')
	@git branch -r
	@git branch -vv
	@echo "pull remote tags down"
	@git pull --tags
	@echo  'latest-tag [  $(shell gh latest-tag) ]'
	@echo  'milestone title [  $(shell  jq '.milestone.title' $(G)/issue.json ) ]'
	@echo "INFO! semver based on latest stragegy[ $(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json )) ]"
	@echo "TASK! update config semver for our new build"
	@sed -i -r "s/^SEMVER=.*/SEMVER=$(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json ))/" config
	@git commit -am 'updated semver based on latest stragegy'
	@echo  'branch name [  $(shell jq '.name' $@) ]'

###############################################################################
# PULL REQUEST PHASE
#  - pull-request
#  - gh create-pr-shipit-comment
#  - pr-status
#  - pr-merge
###############################################################################

pr:
	@$(if $(isMaster),$(error  'need to be on a branch'),echo '## Create Pull Request ##')
	@echo "current branch:   [ $(CURRENT_BRANCH) ]"
	@echo " config semver:   [ $(SEMVER) ]"
	@echo "last release tag: [ $(shell gh latest-tag) ]"
	@echo "release strategy: [ $(shell jq '.milestone.title' $(G)/issue.json ) ]"
	@echo "this release tag  [ $(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json )  ) ]"
	@if [ '$(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json ))' !=  '$(SEMVER)' ] ;\
 then \
 echo 'update semver';\
 sed -i -r "s/^SEMVER=.*/SEMVER=$(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json ))/" config;\
 git commit -am 'update semver'; \
 git push; \
 fi
	@echo "make sure build up to date"
	@$(MAKE) -silent build
	@$(MAKE) -silent pull-request
	@$(MAKE) -silent pr-shipit
	@$(MAKE) -silent pr-status

merge-ready:
	@echo '## $@ ##'
	@echo "Issue Number: [ $(shell jq '.number' $(G)/issue.json) ]"
	@gh get-issue $(shell jq '.number' $(G)/issue.json)
	gh get-pr-combined-status
	@echo "Issue has pull request: [ $(shell jq 'has("pull_request")' $(G)/issue.json) ]"
	@echo "Issue State: [ $(shell jq '.state' $(G)/issue.json) ]"
	@echo "Combined State: [ $(shell jq '.state' $(G)/pr-combined-status.json ) ]"

.PHONY: pr pull-request 

pr-shipit: $(G)/pr-comment.json

pr-status: $(G)/pr-combined-status.json  

gitStatus != git status -s --porcelain

pull-request:
	@echo '## $@ ##'
	@echo '  conditions '
	@echo '--------------'
	@$(if $(gitStatus) , $(error 'git status should be clean' ) , echo ' - git status clean')
	@echo "Issue Number: [ $(shell jq '.number' $(G)/issue.json ) ]"
	@gh get-issue $(shell jq '.number' $(G)/issue.json )
	@echo "Issue State: [ $(shell jq '.state' $(G)/issue.json ) ]"
	@echo "Issue has pull request: [ $(shell jq 'has("pull_request")' $(G)/issue.json ) ]"
	@if [ ! $(shell jq 'has("pull_request")' $(G)/issue.json ) ] ; then echo 'should be false'; false ;fi
	@gh create-pull-request
	@echo "-----------------------------------"


$(G)/pr-comments.json:  $(G)/pull-request.json
	@echo "##[ $@ ]##"
	@gh get-pr-comments
	@echo "-------------------------------------"

$(G)/pr-comment.json: $(G)/pr-comments.json
	@echo "{{{##[ $@ ]##"
	@eval $( jq -r '. | length == 0' $<  ) &&\
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
	@jq '.' <(<$<)
	@echo "if conditions not meet fail. below will eval to true or false "
	@echo 'successful state ' \
 $$( jq '.state == "success"' $< )
	@echo 'statuses array with success state' \
 $$( jq '.statuses | .[] | contains({"state":"success"})' $< )
	@echo 'statuses with all good description ' \
 $$( jq 'contains({statuses: [{"description": "All good"}]})' $< )
	@echo 'both successful state and all good' \
 $$( jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))' $< )
	@eval $$( jq '.state == "success"' $< )
	@eval $$( jq '.statuses | .[] | contains({"state":"success"})' $< )
	@eval $$( jq 'contains({statuses: [{"description": "All good"}]})' $< )
	@eval $$( jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))' $< )
	@echo "pull request combined status all ready to merge"
	@gh merge-pull-request
	@cat $@ | jq '.'

.PHONY: merged  merge

merge:
	@gh info-pr-merge-state
	@make --silent $(G)/merge.json
	@echo 'update json pr status docs'
	@gh info-pr-merge-state
	@echo 'post merge tasks'
	@echo '---------------'
	@echo ' the pull request should now have a merged true status'
	@eval $$( jq '(.merged == true)' $(G)/pull-request.json )
	@echo "latest tag: [ $$(gh latest-tag) ]"
	@echo "    semver: [ $(SEMVER) ]" 
	@echo 'latest milestone: ' $$(gh latest-milestone)
	@echo "head ref: [ $(shell jq '.head.ref' $(G)/pull-request.json ) ]"
	@echo "checkout master: [ $(shell jq '.base.ref'  $(G)/pull-request.json ) ]"
	@$(if $(isMaster),,git checkout $(shell jq '.base.ref' $(G)/pull-request.json))

merged: 
	@echo "##[ $@ ]##"
	@$$(jq -e '.merged' $(G)/merge.json) && jq '.message' $(G)/merge.json
	@echo  'Pull Request URL [ $(shell jq '.url' $(G)/pull-request.json ) ]'
	@gh get-pull-request $(shell jq '.url' $(G)/pull-request.json)
	@echo 'Pull Request state     [ $(shell jq '.state' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged    [ $(shell jq '.merged' $(G)/pull-request.json ) ]'
	@echo 'Pull Request closed at [ $(shell jq '.closed_at' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged at [ $(shell jq '.merged_at' $(G)/pull-request.json ) ]'
	@$$( jq -e '.merged' $(G)/pull-request.json )
	@echo "delete local branch: $(shell jq '.head.ref' $(G)/pull-request.json ) "
	@$(if $(isMaster),git branch -D  $(shell  jq '.head.ref'  $(G)/pull-request.json ) ,)
	@echo "delete remote branch: $(shell jq '.head.ref' $(G)/pull-request.json  ) "
	@$(if $(isMaster),git push origin --delete  $(shell jq '.head.ref' $(G)/pull-request.json ) ,)

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

release:
	@echo '##[ $@ ]##'
	@echo "last release tag: [ $(shell gh latest-tag) ]"
	@echo "release strategy: [ $(shell jq '.milestone.title' $(G)/issue.json ) ]"
	@echo "this release tag  [ $(shell gh update-semver $(shell gh latest-tag) $(shell jq '.milestone.title' $(G)/issue.json )  ) ]"
	@echo "make sure build up to date"
	@$(MAKE) -silent build
	$(MAKE) $(G)/asset_uploaded.json

$(G)/latest-release.json: $(XAR)
	@echo '##[ $@ ]##'
	@echo 'create release using following params'
	@echo 'tag-name: v$(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo 'body: $(shell jq '.body' $(G)/pull-request.json )'
	@echo 'xar: $(wildcard $(XAR))'
	@gh -v create-release 'v$(VERSION)' '$(ABBREV)-$(VERSION)' '$(shell jq ".body" $(G)/pull-request.json )'
	@echo "------------------------------------------------------------------"

# @gh create-release "v$(VERSION)" "$(ABBREV)-$(VERSION)" "$(shell echo $$(<$(G)/pull-request.json) | jq '.body | @sh')"

upload-URL = '$(shell jq '.upload_url' <(<$(G)/latest-release.json ))'

$(G)/asset_uploaded.json: $(G)/latest-release.json
	@echo "##[ $@ ]##"
	@echo "tag-name: [ $(shell jq -r '.tag_name' $< ) ]"
	@echo "    name: [ $(shell jq '.name' $< ) ]" 
	@echo 'upload release using following params'
	@echo "upload-file: $(XAR)"
	@echo 'upload-url: [$(shell jq -r '.upload_url' $< | sed -r 's/\{.+//g' )  ]'
	@echo "contentType: application/expath+xar"
	 gh upload-release-asset \
  '$(XAR)' \
  '$(shell jq -r '.upload_url' $< | sed -r 's/\{.+//g' )?name=$(notdir $(XAR))' \
  'application/expath+xar'
	 @gh get-latest-release
	 @jq '.' $@
	 @echo "------------------------------------------------------------------ "


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

.PHONY: deploy  downloadCount

# ifneq ($(wildcard $(G)/latest-release.json),)
# releaseTagName != echo $$(<$(G)/latest-release.json) | jq '.tag_name'
# releaseName != echo $$(<$(G)/latest-release.json) | jq '.name'
# releaseDownloadUrl !=  echo $$(<$(G)/latest-release.json) | jq '.assets[0] | .browser_download_url'
# endif
# me/gmack/projects/grantmacken/gmack.nz/.github/asset_uploaded.json' 

repoDeploy:
	@echo '           url: [ $(shell jq '.url' $(G)/asset_uploaded.json ) ]'
	@echo '          name: [ $(shell jq '.name' $(G)/asset_uploaded.json ) ]'
	@echo '  download url: [ $(shell jq '.browser_download_url' $(G)/asset_uploaded.json ) ]'
	@echo 'download count: [ $(shell jq '.download_count' $(G)/asset_uploaded.json ) ]'
	@echo '  content type: [ $(shell jq '.content_type' $(G)/asset_uploaded.json) ]'
	@echo '   release tag: [ $(shell jq '.tag_name' $(G)/latest-release.json ) ]'
	@gh get-assets $(shell jq -r '.url' $(G)/asset_uploaded.json )
	@xQdeploy list
	@xQdeploy install
	@xQregister
	@xQdeploy list
	@gh get-assets $(shell jq -r '.url' $(G)/asset_uploaded.json ) && sleep 3
	@$(MAKE) --silent downloadCount
	@echo "------------------------------------------------------"

downloadCount:
	@echo 'download count: [ $(shell jq '.download_count' $(G)/asset_uploaded.json ) ]'


repoDeployRemote:
	@gh -v get-latest-release
	@echo "download url: [ $(shell gh info-asset-download-url ) ]"
	@echo "release tag name [ $(shell gh info-release-tag-name) ]"
	@echo "download count: [ $(shell gh info-asset-download-count ) ]"
	@sudo make hostsRemote
	@xQdeploy list
	@xQdeploy install
	@xQregister
	@xQdeploy list
	@sudo make hostsLocal
	@gh get-latest-release
	@echo "download count: [ $(shell gh info-asset-download-count ) ]"
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
