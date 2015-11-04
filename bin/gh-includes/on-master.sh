#!/bin/bash +x
############################

function branchInfo(){
  echo "INFO!  *CURRENT_BRANCH*: [ ${CURRENT_BRANCH} ]"
}

function branchIsMaster(){
  if [ "${CURRENT_BRANCH}" = 'master' ]
  then
    return 0
  else
    return 1
  fi
}

function omCreateBranch(){
##TODO!
# do prechecks
[ -n "$(git status -s --porcelain --untracked-file=no)" ]  && \
  git add . ; git commit -am 'prep for first run'
    #TODO check for each stage
    #echo "TASK!: pull down the latest changes from origin master"

[ -z "${BRANCH_SELECTED}" ] && return 1
echo "TASK! create local branch: *${BRANCH_SELECTED}*"
echo "CHECK! if *${BRANCH_SELECTED}* does not exist"
chk=$(
  git branch | grep -oP "${BRANCH_SELECTED}"
  )
if [ -z  "${chk}" ] ;  then
  echo "YEP! *${BRANCH_SELECTED}* does *not* exist OK!"
  doTask=$(
	git checkout -b ${BRANCH_SELECTED} origin/master
	)
  chk=$( echo "${doTask}" | grep -oP 'set up to track remote branch' )
  if [ -n "${chk}" ] ; then
	  echo "INFO!: - ${doTask}"
	  local msg=$(
	  git reflog | \
	  head -1 |
	  grep -oP 'checkout:\s.+' )
	  echo "INFO!: ${msg}"
	  echo "DONE!: created local branch: *${BRANCH_SELECTED}*"
  else
	  echo "FAILED!: to create local branch: *${BRANCH_SELECTED}*"
	  return 1
  fi
  # NOTE: we don't have to do this strait away
  # We can make commits an push later on
  # By pushing we are making local commits public
  echo "TASK! push to remote set upstream to branch isolated from master"
  git push -u origin ${BRANCH_SELECTED}
  #todo check if upstream then return
  return 0
else
	echo "FAILURE: TODO if branch exists"
	return 1
fi
git branch -r
git branch -vv
return 0
}




function branchWhenOnMaster(){
[ ${CURRENT_BRANCH} = 'master' ] || return 1
echo "INFO!  *CURRENT_BRANCH*: [ ${CURRENT_BRANCH} ]"
[ -e ${JSN_REPO} ]  || {
  echo "FAILURE! no file ${JSN_REPO}"
  exit 1
  } && parseRepo

#git commit -am 'prep branchWhenOnMaster'
#git push
#
#echo "TASK! working directory up to date with origin"
##The --prune option removes remote-tracking branches that no longer exist on the
#doTask=$( git pull --rebase --prune )
#echo "DONE! ${doTask}"

#exit
##declare vars
#REPO_BRANCHES_URL="$(node -pe "require('${GITHUB_REPO}')['branches_url']" | sed -r 's/\{.+//g')"
#REPO_ISSUES_URL="$(node -pe "require('${GITHUB_REPO}')['issues_url']" | sed -r 's/\{.+//g')"
#REPO_MILESTONES_URL="$(node -pe "require('${GITHUB_REPO}')['milestones_url']" | sed -r 's/\{.+//g')"
#REPO_LABLELS_URL="$(node -pe "require('${GITHUB_REPO}')['labels_url']" | sed -r 's/\{.+//g')"
#
#echo "INFO!  *REPO_MILESTONES_URL*: [ ${REPO_MILESTONES_URL} ]"
#echo "INFO!  *REPO_LABLELS_URL*: [ ${REPO_LABLELS_URL} ]"

local chk=
local doTask=

echo "CHECK! all branches merged into master"
chk=$( git branch --merged | grep -v '\*' )
if [[ -z ${chk} ]] ; then
    echo "YEP! branches are merged into master"
else
    echo "NOPE! all branches *not* merged into master"
    echo "TASK! remove branches not merged into master"
    doTask=$(
    git branch --merged | grep -v '\*' | xargs -n 1 git branch -d
    )
    echo "DONE! removed branches not merged into master"
fi

echo "TASK! when on master branch fetch github issues"
bin/gh get-issues

parseFetchedIssues || return 1
if [ $ISSUES_COUNT -eq 0 ] ; then
  echo ''
  branchCreateNewIssue && return 0 || return 1
#recurse
#  echo "INFO! return to fetch and select from issues"
  #branchWhenOnMaster

fi

# on master select a issue to work on
#   if there is no existing issue you want to work on
#       create a new issue
#   otherwise
#       Fetch the issue
# ISSUES_FOR_BRANCHES

branchGetIssuesForBranches
branchSelectIssueForBranch
if [ -n "${BRANCH_SELECTED}" ] ; then
  if [[ "$BRANCH_SELECTED" =  'CREATE_NEW_ISSUE' ]] ; then
    branchCreateNewIssue  && return 0 || return 1
  fi
  parseBranchName ${BRANCH_SELECTED} || return 1
  repoFetch "${REPO_ISSUES_URL}/${PARSED_ISSUE_NUMBER}" "${GITHUB_ISSUE}"
  branchCreateBranch || return 1
  #git status -sb --porcelain | head -1 | grep -oP '## master'
  #echo 'TODO! - check if on master'
  return 0
else
  echo "FAILURE! - no ISSUES_FOR_BRANCHES selected"
  return 1
fi

}


function omNewIssueMD(){
cat << EOF
  A branch always associated with issue so CURRENT_ISSUE.md repesents the issue
  currently being worked on as a branch
EOF
inputPrompt 'ISSUE_TITLE' 'enter short descriptive' || return 1
echo "INFO! - *ISSUE_TITLE* [ ${ISSUE_TITLE} ]"
omNewIssueLabel 'LABEL_SELECTED' || return 1
omNewIssueMilestone 'MILESTONE_NUMBER'|| return 1
#echo "INFO! - *MILESTONE_NUMBER* [ $MILESTONE_NUMBER ]"
inputPrompt 'ISSUE_SUMMARY' 'enter short one line'
echo "INFO!  *ISSUE_SUMMARY*: [ ${ISSUE_SUMMARY} ]"
inputPrompt 'ISSUE_TASK' 'enter first '
echo "INFO!  *ISSUE_TASK*: [ ${ISSUE_TASK} ]"
## from choices create ${ISSUE_FILE}
cat << EOF | tee ${ISSUE_FILE}
<!--
ISSUE_TITLE="${ISSUE_TITLE}"
ISSUE_LABEL="${LABEL_SELECTED}"
ISSUE_MILESTONE="${MILESTONE_NUMBER}"
-->
${ISSUE_SUMMARY}

- [ ] ${ISSUE_TASK}
- [ ] adjust readme re. issue
EOF

}



###############################################################################
# ISSUE_LABEL
# set a single label
# from array ISSUE_BRANCH_TYPES i.e the types of issues that can become branches
###############################################################################
function omNewIssueLabel(){
local options=()
for item in  "${ISSUE_BRANCH_TYPES[@]}"
    do
       options+=("$(echo "${item}")")
    done
#options+=("OK")
echo "INFO! From options select ${CLR_INPUT}ISSUE_LABEL${CLR_RESET} ➤ "
if ! utilitySelectOption 'LABEL_SELECTED' ; then
    return 1
fi
echo "INFO! - *LABEL_SELECTED* [ ${LABEL_SELECTED} ]"
}

################################################################################
# ISSUE_RELEASE MILESTONES
## from array RELEASE_MILESTONES
## this will detirmine the strategy for the
## version bump from the latest release tag
## TODO! in bin/init create strategy milestone
##  strategy-patch etc
################################################################################
function omNewIssueMilestone(){
local rtrn="${1}"
local string=

readarray RELEASE_MILESTONES <<< \
"$( node -e "\
 J = require('${GITHUB_MILESTONES}');\
 R = require('ramda');\
 var print = function(x){console.log(x.title + ': milestone[' +x.number + '] - '+  x.description)};\
 R.forEach(print,R.project(['title','number', 'description' ], J));")"

local options=()
for item in  "${RELEASE_MILESTONES[@]}"
  do
	options+=("$(echo "${item}")")
  done
echo "INFO! establish a release strategy based on issue milestone"
echo "INFO! From options select *ISSUE_MILESTONE*"
utilitySelectOption 'MILESTONE_SELECTED' || return 1
#MILESTONE_NUMBER#
echo " ${MILESTONE_SELECTED}"
string=$( echo "${MILESTONE_SELECTED}" | grep  -oP '^(\w)+-(\w)+(?=.+$)' )
if [ -n "${string}" ] ; then
  eval ${rtrn}="\"${string}\""
  return 0
else
  return 0
fi
}

function omSetJsonFromIssueMD(){
local jsnBody="$( echo "$ISSUE_BODY" | jq -s -R '.' | jq '{body: .}' )"
local jsnMeta=$(
cat << EOF | jq '{title, assignee, milestone, labels}'
{
  "title": "${ISSUE_TITLE}",
  "assignee": "${GIT_USER}",
  "milestone": "${ISSUE_MILESTONE_NUMBER}",
  "labels": [
    "${ISSUE_LABEL}"
  ]
}
EOF
)

jsn=$(
  echo "${jsnMeta}"  "${jsnBody}" | \
  jq -s '.[0] * .[1] | {title, assignee, milestone, labels, body }'
  )

return 0
}



function branchCreateNewIssue(){
clear
#echo "TASK! create a new issue and post to github"
#
##cat << EOF
##A branch always associated with issue so CURRENT_ISSUE.md repesents the issue
##currently being worked on as a branch
##EOF
#
##echoLine
#local issue_title=
#read -p "enter short descriptive ${CLR_INPUT}ISSUE_TITLE${CLR_RESET} ➥ " issue_title
#echo "INFO!  *ISSUE_TITLE*: [ ${issue_title} ]"
##branchCreateNewIssue
################################################################################
## ISSUE_LABEL
## set a single label
## from array ISSUE_BRANCH_TYPES i.e the types of issues that can become branches
################################################################################
#local options=()
#for item in  "${ISSUE_BRANCH_TYPES[@]}"
#    do
#       options+=("$(echo "${item}")")
#    done
##options+=("OK")
#echo "INFO! From options select ${CLR_INPUT}ISSUE_LABEL${CLR_RESET} ➤ "
#if ! utilitySelectOption 'LABEL_SELECTED' ; then
#    return 1
#fi
#echo "INFO! - LABEL_SELECTED [ ${LABEL_SELECTED} ]"
################################################################################
## set a single milestone
## from array RELEASE_MILESTONES
## this will detirmine the strategy for the
## version bump from the latest release tag
## TODO! in bin/init create strategy milestone
##  strategy-patch etc
################################################################################
#
#readarray RELEASE_MILESTONES <<< \
#"$( node -e "\
# J = require('${GITHUB_MILESTONES}');\
# R = require('ramda');\
# var print = function(x){console.log(x.title + ': milestone[' +x.number + '] - '+  x.description)};\
# R.forEach(print,R.project(['title','number', 'description' ], J));")"
#local options=()
#for item in  "${RELEASE_MILESTONES[@]}"
#  do
#	options+=("$(echo "${item}")")
#  done
#echo "INFO! establish a release strategy based on issue milestone"
#echo "INFO! From options select *ISSUE_MILESTONE*"
#utilitySelectOption 'MILESTONE_SELECTED' || return 1
#
#MILESTONE_NUMBER=$( echo " ${MILESTONE_SELECTED}" | grep  -oP '[0-9]{1,2}(?=.+)' )
#
#echo "INFO! - MILESTONE_NUMBER [ ${MILESTONE_NUMBER} ]"
#
################################################################################
## set a short summary and first task
###############################################################################
#read -p "enter short summary ${CLR_INPUT}ISSUE_SUMMARY${CLR_RESET} ➥ " issue_summary
#echo "INFO!  *ISSUE_SUMMARY*: [ ${issue_summary} ]"
#read -p "enter first task ${CLR_INPUT}ISSUE_TASK_1${CLR_RESET} ➥ " issue_task_1
#echo "INFO!  *issue_task_1*: [ ${issue_task_1} ]"
##echoLine
## from choices create ${ISSUE_FILE}
#cat << EOF | tee ${ISSUE_FILE}
#<!--
#ISSUE_TITLE="${issue_title}"
#ISSUE_LABEL="${LABEL_SELECTED}"
#ISSUE_MILESTONE="${MILESTONE_NUMBER}"
#-->
#${issue_summary}
#
#- [ ] ${issue_task_1}
#- [ ] adjust readme re. issue
#EOF
#
#nano ${ISSUE_FILE}



echo "TASK! prepare for upload post "
echo "INFO! we should be able to read source "
# front-matter
source <(sed -n '1,/-->/p' ${ISSUE_FILE} | sed '1d;$d')
echo "INFO!  - issue meta items"
echo "INFO! - *ISSUE_TITLE*: [ ${ISSUE_TITLE} ]"
echo "INFO! - *ISSUE_LABEL*: [ ${ISSUE_LABEL} ]"
echo "INFO! - *ISSUE_MILESTONE*: [ ${ISSUE_MILESTONE} ]"
echo "INFO! - *ISSUE_BODY*: -"

# get the text
ISSUE_BODY="$( branchEchoIssueBody )"

strISSUE_BODY="$( echo "$ISSUE_BODY"  |
  R -rsc "join  '\n'"
  )"
#strISSUE_BODY=$(echo "$ISSUE_BODY"  | R -rsc \"join  '\n'\")

#jsnBody="$( echo "$ISSUE_BODY" | jq -s -R '.' | jq '{body: .}' )"
#
jsn=$(
cat << EOF
{
  "title": "${ISSUE_TITLE}",
  "assignee": "${GIT_USER}",
  "milestone": "${ISSUE_MILESTONE}",
  "labels": [
    "${ISSUE_LABEL}"
  ],
  "body" : ${strISSUE_BODY}
}
EOF
)


echo "INFO! REPO_ISSUES_URL [ ${REPO_ISSUES_URL} ]"
echo "INFO! json payload - "
##echoLine
echo ${jsn} | jq '.'
##echoLine
#
if repoCreate "${REPO_ISSUES_URL}" "${JSN_ISSUE}" "${jsn}"
then
  parseFetchedIssue && return 0 || return 1
else
  return 1
fi
}

#function branchFetchIssues(){
#echo "TASK! get issues from github that can become branches"
#local chk=
#local jsnGITHUB_ISSUES=
#local labels="$( echo "${ISSUE_BRANCH_TYPES[@]}" | tr ' ' ',' )"
## note param is label not labels
## https://developer.github.com/v3/issues/
## if issues list gets to big use more filters e.g. state and since
#local URL="${REPO_ISSUES_URL}?label=${labels}"
#repoFetch ${URL} ${GITHUB_ISSUES} || return 1
#ISSUES_COUNT=$(
# node -pe "J = require('${GITHUB_ISSUES}');\
# R = require('ramda');\
# R.length(J)"
# )
#echo "INFO! - *ISSUES_COUNT*: [ ${ISSUES_COUNT} ]"
#}

function omSetIssuesForBranches(){
echo "TASK! from fetched issues set IssuesForBranches array"
#echo "$(<${JSN_ISSUES})" | jq -c \
#    '.[] |  [ .labels[].name, .number ,.title ]' | \
#    sed -r 's/(\["|"\])//g' | \
#    sed -r 's/(\s|,")/-/g' | \
#    sed -r 's/(",)/-/g' > $TEMP_FILE
#readarray ISSUES_FOR_BRANCHES < $TEMP_FILE
echo "$(<${JSN_ISSUES})" | jq '.'

readarray ISSUES_FOR_BRANCHES < <(
  echo "$(<${JSN_ISSUES})" | jq -c \
  '.[] |  [ .labels[].name, .number ,.title ]' | \
  sed -r 's/(\["|"\])//g' | \
  sed -r 's/(\s|,")/-/g' | \
  sed -r 's/(",)/-/g'
)
echo "INFO! - ${#ISSUES_FOR_BRANCHES[@]} ISSUES_FOR_BRANCHES"
count=0
for i in ${!ISSUES_FOR_BRANCHES[@]}; do
  str=$( echo  "${ISSUES_FOR_BRANCHES[${i}]}" | sed -r 's/-/ /g' )
  (( count++ ))
  echo "INFO! [${count}] ${str}"
done 
echo "DONE! set issues for branches task completed"
}

function branchSelectIssueForBranch(){
clear    
#intro
cat << EOF
On master - We need to 
 1. Select an existing issue (feature, bug ) to work on, or 
 2. Add a new issue to github then select this issue.
 
our existing github issues  (that can become branches )
are displayed in a specific way

{ISSUE_LABEL}  {ISSUE_NUMBER}  {ISSUE_TITLE}
EOF
#echoLine
echo "${#ISSUES_FOR_BRANCHES[@]}"
local options=()
for i in "${!ISSUES_FOR_BRANCHES[@]}" 
    do
       item=$( echo "${ISSUES_FOR_BRANCHES[i]}" )
       options+=("${item}")
    done
options+=("CREATE_NEW_ISSUE")
#options+=("OK")

echo "INFO! Select issue for branch"
utilitySelectOption 'BRANCH_SELECTED'
echo "INFO! - *BRANCH_SELECTED*: [ ${BRANCH_SELECTED} ]"
#echoLine
}


function omPriorReleaseConditions(){
[ -e "${JSN_REPO}" ]  || exit 1
[ -n "$( echo ${CURRENT_BRANCH} | grep -oP '^master$')" ] && {
 ON_MASTER='true'
 echo "INFO! - *ON_MASTER* [ ${ON_MASTER} ]"
 } || {
  echo "FAILURE! - *ON_MASTER* [ ${ON_MASTER} ]"
  return 1
  }
[ -n "$( echo ${TERM})" ] && {
IN_TERMINAL='true'
echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
} || {
IN_TERMINAL='false'
echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
}

if [ -z "$(git status -s --porcelain)" ]  ; then
  echo "OK! - *REPO CLEAN* "
else
  echo "FAIL! - REPO *NOT* CLEAN "
  git status -s --porcelain
  #return 1
fi

if [ -e ${SEMVER_FILE} ] ; then
  SEMVER=$(<${SEMVER_FILE})
  echo "INFO! *CURRENT_SEMVER* [ ${SEMVER} ]"
fi

if [ "${SEMVER}" = "${LATEST_TAG}" ] ; then
  echo "INFO! *CURRENT_SEMVER* - ${SEMVER} equals *LATEST_TAG* - ${LATEST_TAG} "
# echo "${RELEASE_NEW_VERSION}" > ${SEMVER_FILE}
else
  echo "INFO! *CURRENT_SEMVER* - ${SEMVER} not equal to *LATEST_TAG* - ${LATEST_TAG}"
fi

if [ "${RELEASE_TAG_NAME}" = "${LATEST_TAG}" ] ; then
  echo "INFO! *RELEASE_TAG_NAME* - ${RELEASE_TAG_NAME} equals *LATEST_TAG* - ${LATEST_TAG} "
# echo "${RELEASE_NEW_VERSION}" > ${SEMVER_FILE}
  #return 1
else
  echo "INFO! *RELEASE_TAG_NAME* - ${RELEASE_TAG_NAME} not equal to *LATEST_TAG* - ${LATEST_TAG}"
fi

}


function omReleaseTasks(){
  #conditions

#touch config
#make repo


# Validating old version against latest head hash
#oldVersionHash="$( git rev-list ${RELEASE_CURRENT_VERSION} | head -n 1 )"
##echoMD 'INFO! - RELEASE_CURRENT_VERSION_HASH: [ ${oldVersionHash} ]'
#headHash=(`git log --pretty=format:"%H" -n 1`)
##echoMD 'INFO! - HEAD_HASH: [ ${headHash} ]'
#echo "CHECK! git log to see if any new commits since *last release*"
#chkCommitsSinceLastRelease=$(
#	git log --pretty=format:'* %s %h' ${oldVersionHash}..${headHash} \
#	2> /dev/null
#	)
#if [ -z "${chkCommitsSinceLastRelease}" ]; then
#	echo "NOPE!  git repo has NO commits since last release"
#  else
#	numberOfCommits=$( wc -l <<<"${chkCommitsSinceLastRelease}" )
#	echo "YEP!  git repo has ${numberOfCommits} commits since last release"
#	echo "INFO! SANITY CHECK! do we have too many commits since last release? "
#fi
#echo "INFO! On release tag ${RELEASE_CURRENT_VERSION} \
#Working towards ${STRATEGY} ${RELEASE_NEW_VERSION}"

echoMD 'TASK! create an annotated tag'
doTask=$(
  git tag \
  -a ${SEMVER} \
  -m '${MILESTONE_TITLE} based on ${ISSUE_TITLE}'
  )
#
echo "TASK! push to remote"
doTask=$( git push origin --tags )
echo "DONE! ${doTask}"
bin/gh get-tags
parseTags
jsn=$(
cat << EOF  | jq '.'
{
  "tag_name": "${LATEST_TAG}",
  "target_commitish":"master",
  "name":"${ABBREV}-${LATEST_TAG}",
  "body":"${MILESTONE_TITLE} merged into master \nISSUE - ${ISSUE_TITLE}",
  "draft":false,
  "prerelease":false
}
EOF
)
echo "${jsn}" | jq '.'
repoCreate "${REPO_RELEASES_URL}" "${JSN_RELEASE}" "${jsn}"
parseRelease
#
requestURL="${RELEASE_UPLOAD_URL}${RELEASE_NAME}"
outFile="${JSN_ASSET_UPLOADED}"
contentType='application/zip'
upFile="pkg/xar/${RELEASE_NAME}.xar"

if [ -e ${upFile} ] ; then
  repoUpload "${requestURL}" "${outFile}" "${upFile}"  "${contentType}"
  parseAssetUploaded
else
  echo "FAILURE! - no upload file"
fi
bin/gh get-latest-release
}

omCreateAnnotatedTag(){
echoMD 'TASK! create an annotated tag'
doTask=$(
  git tag \
  -a ${RELEASE_NEW_VERSION} \
  -m '${ISSUE_MILESTONE} based on ${ISSUE_TITLE}'
  )
echo "DONE! ${doTask}"
echo "TASK! push to remote"
doTask=$( git push origin --tags )
echo "DONE! ${doTask}"
}


omUpdateSemver(){
[ -e ${SEMVER_FILE} ]  && SEMVER=$(<${SEMVER_FILE}) 
# depends on
[ -z "${LATEST_TAG}" ] &&  parseTags  > /dev/null
[ -z "${PR_MILESTONE_TITLE}" ] && parsePullRequest 
[ -z "${FETCHED_ISSUE_MILESTONE_TITLE}" ] && parseFetchedIssue
[ -z "${currentVersion}" ] && \
    currentVersion="$( xq app-semver  | sed 's/v//' )"

echo "INFO! *SEMVER* [ ${SEMVER} ]"
echo "INFO! *LATEST_TAG* [ ${LATEST_TAG} ]"
echo "INFO! *INSTALLED_VERSION* [ ${INSTALLED_VERSION} ]"
echo "INFO! *PR_MILESTONE_TITLE* [ ${PR_MILESTONE_TITLE} ]"
echo "INFO! *FETCHED_ISSUE_MILESTONE_TITLE* [ ${FETCHED_ISSUE_MILESTONE_TITLE} ]"
[ -z "${SEMVER}" ] && return 1
[ -z "${LATEST_TAG}" ] && return 1
[ -z "${PR_MILESTONE_TITLE}" ] && return 1
[ -z "${FETCHED_ISSUE_MILESTONE_TITLE}" ] && return 1
echo 'OK!'
# conditions
#  issue milestone and pr milestone should be the same                 
[ "${PR_MILESTONE_TITLE}" = "${FETCHED_ISSUE_MILESTONE_TITLE}" ] || return 1
if [ "${SEMVER}" = "${LATEST_TAG}" ] ; then
  echo "INFO! *CURRENT_SEMVER* - ${SEMVER} equals *LATEST_TAG* - ${LATEST_TAG} "
  return 1
else
  echo "INFO! *CURRENT_SEMVER* - ${SEMVER} not equal to *LATEST_TAG* - ${LATEST_TAG}"
fi

# lastTaggedCommi=$( git rev-list --tags --max-count=1 )
# currentVersionString=$( git describe --tags ${lastTaggedCommit} )
# currentVersion=$(
# echo "$( git describe --tags ${lastTaggedCommit} )" |
# sed 's/v//'
# )
# echo "INFO! *currentVersion* [ ${currentVersion} ]"
# return
#  LATEST_TAG is from the fetched taglist on gitub
#  currentTag is the last tagged stagged commit
#  
semverMajor=$( cut -d'.' -f1 <<<  ${currentVersion} )
semverMinor=$( cut -d'.' -f2 <<<  ${currentVersion} )
semverPatch=$( cut -d'.' -f3 <<<  ${currentVersion} )
RELEASE_CURRENT_VERSION="v${semverMajor}.${semverMinor}.${semverPatch}"
case "${PR_MILESTONE_TITLE}" in
  strategy-patch)
  RELEASE_NEW_VERSION="v${semverMajor}.${semverMinor}.$((semverPatch + 1))"
  ;;
  strategy-minor)
  RELEASE_NEW_VERSION="v${semverMajor}.$((semverMinor + 1)).0"
  ;;
  strategy-major)
  RELEASE_NEW_VERSION="v$((semverMajor + 1)).0.0"
  ;;
  *)
  RELEASE_NEW_VERSION="v${semverMajor}.${semverMinor}.$((semverPatch + 1))"
esac

echo "INFO! - *RELEASE_CURRENT_VERSION* [ ${RELEASE_CURRENT_VERSION} ]"
echo "INFO! - *RELEASE_NEW_VERSION* [ ${RELEASE_NEW_VERSION} ]"
if [ -n "$( git tag | grep ${RELEASE_NEW_VERSION} )" ] ; then
   echo 'FAILURE!  release already exists '
   exit 1
fi


if [ ! "${SEMVER}" = "${RELEASE_NEW_VERSION}" ] ; then
 echo "${RELEASE_NEW_VERSION}" > ${SEMVER_FILE}
fi


}

