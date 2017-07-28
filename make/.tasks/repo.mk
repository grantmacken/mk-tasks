
define repoHelp
=========================================================
CURRENT BRANCH: $(CURRENT_BRANCH)

REPO TASKS:

make issue

---------------------------------------------------------
TASKS : make tasks that can be invoked in this repo 

 - issue
 - pr
 - merge
 - merged
 - release
 - asset
 - deploy

PHASE 1 - ISSUE WITH TASK LIST
 make issue
  on master invoking issue will ...
  - create issue markdown file from a template
  - create an issue on github based on markdown
  - creates a local branch with branch name based on issue
  - pushes branch to remote, so local branch starts to track remote branch
  on branch
  - invoking issue will: ...  patch issue

PHASE 2 - PULL REQUEST PHASE
  - pr
    - pull-request
    - pr-shipit ... creates a Looks Good To Me shiptit comment
    - pr-status ... creates a All Good status
Phase 3
  - is-merge-ready ... check if ready to merge
  - merge          ... merge then 
  - merged

Phase 4
  - release     ...   create github release 
  - asset       ...   create deployment xar based on release
  - deploy      ...   deploy xar

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

onBranch != git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///'
onMaster != git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///' | grep -oP '^master$$'
isReachable != dig @8.8.8.8 +short github.com | grep -oP '^([0-9]{1,3}[\.]){3}[0-9]{1,3}$$' | head -1

cleanFetched = $(shell \
 if [ -e $(G)/$(1).json ];then rm $(G)/$(1).json; fi;\
 if [ -e $(G)/headers/$(1).txt ];then rm $(G)/headers/$(1).txt; fi;\
 if [ -e $(G)/etags/$(1).etag ];then rm $(G)/etags/$(1).etag ; fi )

lastTag != if [ -e $(G)/tags.json ];then jq -r -c '.[0] | .name' $(G)/tags.json;fi
ghLatestReleaseTagName != if [ -e $(G)/latest-release.json ];then jq -r -c '.tag_name' $(G)/latest-release.json;fi

mdIssueTitle !=  \
 if [ -e issue.md ];\
 then source <(sed -n '1,/-->/p' issue.md | sed '1d;$$d') && \
 echo $$ISSUE_TITLE;\
 fi

mdIssueLabel != \
 if [ -e issue.md ];\
 then source <(sed -n '1,/-->/p' issue.md | sed '1d;$$d') && \
 echo $$ISSUE_LABEL;\
 fi

mdIssueMilestone != \
 if [ -e issue.md ];\
 then source <(sed -n '1,/-->/p' issue.md | sed '1d;$$d') && \
 echo $$ISSUE_MILESTONE;\
 fi

mdIssueLineCount != if [ -e issue.md ];\
 then sed -n '1,/-->/p' issue.md |  wc -l ;\
 fi

mdIssueBody != if [ -e issue.md ];\
 then sed '1,$(mdIssueLineCount)d;$$d' issue.md | jq -s -R '.' | jq '{body: .}';\
 fi

mdIssueSummary != if [ -e issue.md ];\
 then  sed '1,$(mdIssueLineCount)d;$$d' issue.md | head -1;\
 fi

branchSlug != if [ -e $(G)/issue.json ]; then \
 jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $(G)/issue.json | sed 's/\s/-/g';\
fi

repo:
	$(MAKE) $(G)/repo.json

# TODO! incorp  gh default-labels and default milestone


$(G)/repo.json:
	@echo "##[ $@ ]##"
	@mkdir -p  $(dir $@)

#######################
# ISSUE WITH TASK LIST
# git remote show origin
# git branch -vv
# git branch -a
##@echo "remote tag:  [ $(lastTag) ]"
##@gh get-latest-release
##@echo "release tag: [ $(ghLatestReleaseTagName) ]"
##@echo "local tag:   [ $(shell git describe --abbrev=0 --tags) ]"
##@$(if $(onMaster),echo 'is on master: [ $(onMaster) ]',echo 'is on master: [ nope! ]')
##@if [[ '$(shell git describe --abbrev=0 --tags)' != '$(lastTag)' ]] ;\
# then echo 'local tags need updating';fi

.PHONY: issue issue-clean issue-patch deploy

gitLog:
	@clear
	@git --no-pager log \
  -n 10\
 --pretty=format:'%Cred%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'

  # -n 10\
 # --graph \
 # --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' \
 # --abbrev-commit \
 # --date=relative

issue:
	@echo "## $@ ##"
	@echo 'On Branch: [ $(onBranch) ]'
	@git status --short
	@$(if $(onMaster),\
 $(MAKE) --silent issue-clean && \
 $(MAKE) --silent $(G)/branch.json , \
 $(MAKE) --silent issue-patch )

issue-clean:
	@echo "##[ $@ ]##"
	@if [ -e issue.md ] ; then rm issue.md; fi
	@$(call cleanFetched,issue)
	@$(call cleanFetched,branch)
	@gh get-repo
	@gh get-milestones
	@gh get-labels
	@gh get-tags
	git pull origin master
	git fetch --prune

issue.md: export issueTemplate:=$(issueTemplate)
issue.md:
	@echo "##[ $@ ]##"
	@echo "$${issueTemplate}" > $@
	@read -p "enter issue title ➥ " title;\
 sed -i -r "s/^ISSUE_TITLE=.*/ISSUE_TITLE='$$title'/" $@;\
 sed -i -r "s/^WIP .*/WIP $$title/" $@;

$(G)/issue.json: issue.md
	@echo "##[ $@ ]##"
	@gh create-issue

$(G)/branch.json: $(G)/issue.json
	@echo "##[ $@ ]##"
	@[ -e $< ]
	@echo 'issue url: [ $(shell jq '.url' $< ) ]' 
	@echo 'issue numbe/r:     [ $(shell jq '.number' $< ) ]'
	@echo 'milestone number: [ $(shell jq '.milestone.number' $< ) ]'
	@echo 'issue title       [ $(shell jq '.title' $< ) ]' 
	@echo $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g')
	@$(if $(onMaster),\
 git checkout -b $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g'),)
	@echo 'push new local branch to remote '
	@git push && git remote show origin
	@gh get-branch \
 $(shell jq -r -c '"\(.milestone.title)-\(.number)-\(.title)"' $< | sed 's/\s/-/g') && \
 echo  "branch name [ $(shell jq '.name' $@ )]"
	@git branch -a
	@git branch -vv

issue-patch:
	@echo "##[ $@ ]##"
	@echo 'issue number: [ $(shell jq '.number' $(G)/issue.json) ]'
	@echo 'issue url: [ $(shell jq '.url' $(G)/issue.json)) ]'
	@echo 'milestone number: [ $(shell jq '.milestone.number' $(G)/issue.json) ]'
	@gh patch-issue $(shell jq '.number' $(G)/issue.json)

###############################################################################
# PULL REQUEST PHASE
#  - pull-request
#  - gh create-pr-shipit-comment
#  - pr-status
#  - pr-merge
###############################################################################

pr:
	@$(if $(onMaster),$(error  'need to be on a branch'),echo '## Create Pull Request ##')
	@echo "current branch:   [ $(onMaster) ]"
	@echo "last release tag: [ $(lastTag) ]"
	@echo "release strategy: [ $(releaseStrategy) ]"
	@echo "this release : [ $(nextTag) ]"
	@echo "make sure build up to date"
	@$(MAKE) -silent build
	@$(MAKE) -silent pull-request
	@$(MAKE) -silent pr-shipit
	@$(MAKE) -silent pr-status

is-merge-ready:
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
# @echo "------------------------------------------------------------------ "
# $(G)/pr-combined-status.json

merge-clean:
	@echo "##[ $@ ]##"
	@$(call cleanFetched,merge)

merge:
	@echo "##[ $@ ]##"
	@$(call cleanFetched,merge)
	gh get-pr-combined-status
	@echo "NOTE: if conditions not meet fail. below will eval to true or false "
	@echo 'successful state ' \
 $$( jq '.state == "success"' $(G)/pr-combined-status.json )
	@echo 'statuses array with success state' \
 $$( jq '.statuses | .[] | contains({"state":"success"})' $(G)/pr-combined-status.json )
	@echo 'statuses with all good description ' \
 $$( jq 'contains({statuses: [{"description": "All good"}]})' $(G)/pr-combined-status.json )
	@echo 'both successful state and all good' \
 $$( jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))' $(G)/pr-combined-status.json )
	@eval $$( jq '.state == "success"' $(G)/pr-combined-status.json)
	@eval $$( jq '.statuses | .[] | contains({"state":"success"})' $(G)/pr-combined-status.json )
	@eval $$( jq 'contains({statuses: [{"description": "All good"}]})' $(G)/pr-combined-status.json )
	@eval $$( jq '(.state == "success") and (contains({statuses: [{"description": "All good"}]}))' $(G)/pr-combined-status.json )
	@echo "pull request combined status all ready to merge"
	@gh get-current-pull-request
	@echo 'Pull request current state'
	@echo 'merged: ' $$( jq '.merged' $(G)/pull-request.json )
	@echo 'mergeable ' $$( jq '.mergeable' $(G)/pull-request.json )
	@echo 'mergeable_state ' $$( jq '.mergeable_state' $(G)/pull-request.json )
	@echo 'state ' $$( jq '.state' $(G)/pull-request.json )
	@echo 'title' $$( jq '.title' $(G)/pull-request.json )
	@echo 'body' $$( jq '.body' $(G)/pull-request.json )
	@echo 'number' $$( jq '.number' $(G)/pull-request.json )
	@echo 'milestone' $$( jq '.milestone.title' $(G)/pull-request.json )
	@echo 'head sha' $$( jq '.head.sha' $(G)/pull-request.json )
	@jq -r '. | [ .url,  (.number | tostring),  .title, .head.sha ] | @sh ' $(G)/pull-request.json
	@gh merge-pull-request \
 $(shell jq -r '. | [ .url,  (.number | tostring),  .title, .head.sha ] | @sh ' $(G)/pull-request.json)
	@echo 'on branch:' $(onBranch)
	@echo 'merged: ' $$( jq '.merged' $(G)/merge.json )
	@echo 'message: ' $$( jq '.message' $(G)/merge.json )
	@echo 'sha: ' $$( jq '.sha' $(G)/merge.json )
	@jq -r '.url'  $(G)/pull-request.json
	@gh get-pull-request $$( jq -r '.url' $(G)/pull-request.json )
	@echo '# Check Pull Request Current State #'
	@echo 'Pull Request state     [ $(shell jq '.state' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged    [ $(shell jq '.merged' $(G)/pull-request.json ) ]'
	@echo 'Pull Request closed at [ $(shell jq '.closed_at' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged at [ $(shell jq '.merged_at' $(G)/pull-request.json ) ]'
	@echo 'post merge tasks'
	@echo '---------------'
	@echo ' the pull request should now have a merged true status'
	@eval $$( jq '(.merged == true)' $(G)/pull-request.json )
	@echo "latest tag: [ $(lastTag) ]"
	@echo 'latest milestone: ' $$(gh latest-milestone)
	@echo "head ref: [ $(shell jq '.head.ref' $(G)/pull-request.json ) ]"
	@echo "base ref: [ $(shell jq '.base.ref' $(G)/pull-request.json ) ]"
	@$(if $(onMaster),,git checkout $(shell jq '.base.ref' $(G)/pull-request.json))
	@git remote show origin


merged:
	@echo "##[ $@ ]##"
	@echo '$(shell jq -r '.message' $(G)/merge.json)'
	@gh get-pull-request $(shell jq '.url' $(G)/pull-request.json)
	@echo '# Check Pull Request Current State #'
	@echo 'Pull Request state     [ $(shell jq '.state' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged    [ $(shell jq '.merged' $(G)/pull-request.json ) ]'
	@echo 'Pull Request closed at [ $(shell jq '.closed_at' $(G)/pull-request.json ) ]'
	@echo 'Pull Request merged at [ $(shell jq '.merged_at' $(G)/pull-request.json ) ]'
	@echo "delete local branch: $(shell jq '.head.ref' $(G)/pull-request.json ) "
	@$(if $(onMaster),git branch -D  $(shell  jq '.head.ref'  $(G)/pull-request.json ) ,)
	git branch
	@echo "delete remote branch: $(shell jq '.head.ref' $(G)/pull-request.json  ) "
	@$(if $(onMaster),git push origin --delete  $(shell jq '.head.ref' $(G)/pull-request.json ) ,)
	git branch -r
	git pull --tags
	git pull
	@$(call cleanFetched,branch)




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
# $(if $(isReachable),,)
###############################################################################

release:
	@echo '##[ $@ ]##'
	@gh get-tags
	@gh get-pull-request $(shell jq '.url' $(G)/pull-request.json)
	@echo "last release tag: [ $(lastTag) ]"
	@echo "release strategy: [ $(shell jq '.milestone.title' $(G)/issue.json ) ]"
	@echo "this release tag [ $(shell gh update-semver $(lastTag) $(shell jq '.milestone.title' $(G)/issue.json )) ]"
	@echo "make sure build up to date ... "
	@$(MAKE) -silent build
	@echo '##[ $@ ]##'
	@echo 'create release using following params'
	@echo 'tag-name: v$(VERSION)'
	@echo 'name: $(ABBREV)-$(VERSION)'
	@echo 'body: $(shell jq  -r '.body' $(G)/pull-request.json )'
	@echo 'xar: $(wildcard $(XAR))'
	@gh -v create-release 'v$(VERSION)' '$(ABBREV)-$(VERSION)' '$(shell jq ".body" $(G)/pull-request.json )'

asset:
	@echo '##[ $@ ]##'
	@gh get-latest-release
	@echo "tag-name: [ $(shell jq -r '.tag_name' $(G)/latest-release.json ) ]"
	@echo "    name: [ $(shell jq '.name' $(G)/latest-release.json ) ]" 
	@echo 'upload release using following params'
	@echo "upload-file: $(XAR)"
	@echo 'upload-url: [ $(shell jq -r '.upload_url' $(G)/latest-release.json | sed -r 's/\{.+//g' )  ]'
	@echo "contentType: application/expath+xar"
	@gh upload-release-asset \
  '$(XAR)' \
  '$(shell jq -r '.upload_url' $(G)/latest-release.json | sed -r 's/\{.+//g' )?name=$(notdir $(XAR))' \
  'application/expath+xar'

deploy:
	@gh get-assets $(shell jq -r '.url' $(G)/asset_uploaded.json )
	@echo '           url: [ $(shell jq '.url' $(G)/asset_uploaded.json ) ]'
	@echo '          name: [ $(shell jq '.name' $(G)/asset_uploaded.json ) ]'
	@echo '  download url: [ $(shell jq '.browser_download_url' $(G)/asset_uploaded.json ) ]'
	@echo 'download count: [ $(shell jq '.download_count' $(G)/asset_uploaded.json ) ]'
	@echo '  content type: [ $(shell jq '.content_type' $(G)/asset_uploaded.json) ]'
	@echo '   release tag: [ $(shell jq '.tag_name' $(G)/latest-release.json ) ]'
	@gh get-assets $(shell jq -r '.url' $(G)/asset_uploaded.json )
	@xQdeploy list
	@sleep 5
	@xQdeploy install && \
 sleep 5 && \
 xQregister && \
 sleep 5 && \
 xQdeploy list

deployed:
	@gh get-assets $(shell jq -r '.url' $(G)/asset_uploaded.json ) && \
 echo 'download count: [ $(shell jq '.download_count' $(G)/asset_uploaded.json ) ]'
	@[ $(shell jq '.download_count' $(G)/asset_uploaded.json ) -gt 0 ] && xQregister
	@echo "------------------------------------------------------"


