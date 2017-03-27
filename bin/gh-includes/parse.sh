#!/bin/bash +x
############################

function parseIntoETAG(){
  echo ${1} | sed s%\.json%\.etag% | sed s%/%/etags/%
}

function parseIntoHEADER(){
  echo ${1} | sed s%\.json%\.txt% | sed s%/%/headers/%
}

function parseIntoNodeFS(){
  echo ${1} | sed s%^\.%\./\.%
}

function parseBranchName(){
#declare vars
$verbose && echo 'Parse Branch Name'
local branchName="${1}"
if [ -z "${branchName}" ] ; then
 branchName="${CURRENT_BRANCH}"
fi
$verbose && echo "INFO! topic branch-name can be parsed into LABEL NUMBER TITLE"
$verbose && echo "INFO! *branch-name* [ ${branchName} ]"
PARSED_ISSUE_LABEL=$(
    echo  "${branchName}" |
    cut -d\- -f1
    )
PARSED_ISSUE_NUMBER=$(
    echo  "${branchName}" |
    cut -d\- -f2
    )
PARSED_ISSUE_TITLE=$(
    echo ${branchName} |
    grep -oP '[a-z]{1,10}+-[0-9]{1,4}-\K(.+)' |
    tr '-' ' '
    )
#check if we can parse branch name
local msg='can not parse branch name'
if [ -z "${PARSED_ISSUE_LABEL}" ] ; then
    echo "FAILURE! ${msg} - empty PARSED_ISSUE_LABEL "
    return 1
else
    if [[ -n "$(echo "${PARSED_ISSUE_LABEL}" | grep -oP '^[a-z]{1,20}$' )" ]]
    then
       $verbose &&  echo "INFO! - *PARSED_ISSUE_LABEL*: [ ${PARSED_ISSUE_LABEL} ]"
    else
        echo "FAILURE! ${msg} malformed PARSED_ISSUE_LABEL"
       return 1
    fi
fi

if [ -z "${PARSED_ISSUE_NUMBER}" ] ; then
    echo "FAILURE! ${msg} PARSED_ISSUE_NUMBER"
    return 1
else
    if [[ -n "$(echo "${PARSED_ISSUE_NUMBER}" | grep -oP '^[0-9]{1,5}$' )" ]]
    then
        $verbose && echo "INFO! - *PARSED_ISSUE_NUMBER*: [ ${PARSED_ISSUE_NUMBER} ]"
    else
        echo "FAILURE! ${msg} : PARSED_ISSUE_NUMBER"
       return 1
    fi
fi

if [ -z "${PARSED_ISSUE_TITLE}" ] ; then
    echo "FAILURE! ${msg} : PARSED_ISSUE_TITLE"
    return 1
else
     $verbose && echo "INFO! - *PARSED_ISSUE_TITLE*: [ ${PARSED_ISSUE_TITLE} ]"
fi
}

function parseTags(){
$verbose && echo 'parse tags'
jsnTAGS="$(<${JSN_TAGS})"
LATEST_TAG="$(

echo "${jsnTAGS}" |
jq -r -c '.[0] | .name '
)"
if ($verbose) then
  echo "INFO! - *LATEST_TAG*: [ ${LATEST_TAG} ]"
else
  echo "${LATEST_TAG}"
fi
}

function parseFetchedIssues(){
[ -e "${JSN_ISSUES}" ] || {
echo "FAILURE: file required ${JSN_ISSUES}"
return 1
}
local jsnFile="$(parseIntoNodeFS ${JSN_ISSUES})"
#echo "TASK! get issues from github that can become branches"
## note param is label not labels
## https://developer.github.com/v3/issues/
## if issues list gets to big use more filters e.g. state and since
$verbose && echo $(<${JSN_ISSUES}) | jq '.'
ISSUES_COUNT=$( node -e "require('${jsnFile}').length" )
$verbose && echo "INFO! - *ISSUES_COUNT*: [ ${ISSUES_COUNT} ]"

nSTR="J = require(${jsnFile});\
 R = require('ramda');\
 print = function(x){ ;\
 title = R.prop('title',x);\
 number = R.prop('number',x);\
 state = R.prop('state',x);\
 milestone_number = R.path(['milestone', 'number'], x);\
 milestone_title = R.path(['milestone', 'title'], x);\
 label = R.prop('labels',x)[0].name
 zipped = R.zipObj(\
 ['title', 'number', 'state', 'label' , 'milestone_number', 'milestone_title'], \
 [title, number, state, label, milestone_number,  milestone_title]);\
 return zipped;\
};\
 console.log(R.toString(R.chain(print, J)))
"
node -e "${nSTR}"
}

function parseIntoArrayIssuesForBranches(){
if [ ! -e "${JSN_ISSUES}" ] ; then
  echo "FAILURE: file required ${JSN_ISSUES}"
  return 1
fi
local jsnFile="$(parseIntoNodeFS ${JSN_ISSUES})"
local nSTR="J = require(${jsnFile});\
 R = require('ramda');\
 print = function(x){ ;\
 title = R.prop('title',x).replace(/\\s/g,'-');\
 number = R.prop('number',x);\
 label = R.prop('labels',x)[0].name
 appended = R.append(\
 [label, number, title], \
 []);\
 flattened = R.flatten(appended);\
 joined = R.join('-', flattened);;\
 return joined;\
};\
 console.log(R.toString(R.chain(print, J)))
"
node -e "${nSTR}" | jq '.[]'
IFS=$'\n\r'
readarray ISSUES_FOR_BRANCHES <<< "$(node -e "${nSTR}" | jq '.[]')"
echo "INFO! - ${#ISSUES_FOR_BRANCHES[@]} ISSUES_FOR_BRANCHES"
count=0
for i in ${!ISSUES_FOR_BRANCHES[@]}; do
  str=$( echo  "${ISSUES_FOR_BRANCHES[${i}]}" | sed -r 's/-/ /g' )
  (( count++ ))
  echo "INFO! [${count}] ${str}"
done
echo "DONE! set issues for branches task completed"
}

function parseFetchedIssue(){
  $verbose && echo 'Parse Fetched Issue' 
  if [ ! -e "${JSN_ISSUE}" ] ; then
    echo "FAILURE: file required ${JSN_ISSUE}"
    return 1
  fi
  local jsnFile="$(parseIntoNodeFS ${JSN_ISSUE})"
  # local nSTR=
  ISSUE_PULLS_URL=
  if [ -z "$(node -pe "require('${jsnFile}')['pull_request']" | grep -oP 'undefined')" ]
  then
    ISSUE_PULLS_URL="$(node -pe "require('${jsnFile}')['pull_request']['url']")"
  fi

  local nSTR="J = require('${jsnFile}');\
    console.log('FETCHED_ISSUE_URL=' + J.url );\
    console.log('FETCHED_ISSUE_NUMBER=' + J.number);\
    console.log('FETCHED_ISSUE_STATE=' + J.state);\
    console.log('FETCHED_ISSUE_TITLE=\'' + J.title + '\'') ;\
    console.log('FETCHED_ISSUE_BODY=\'' + J.body + '\'') ;\
    console.log('FETCHED_ISSUE_MILESTONE_DESCRIPTION=\'' + J.milestone.description + '\'') ;\
    console.log('FETCHED_ISSUE_MILESTONE_TITLE=\'' + J.milestone.title + '\'') ;\
    console.log('FETCHED_ISSUE_LABEL=\'' + J.labels[0].name + '\'') ;\
    "
  $verbose && node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
  source <(node -e "${nSTR}")
}

function parseIssueMD(){
  # front-matter as a source
  [ -e ${ISSUE_FILE} ] || return 1
  [ -e ${JSN_LABELS} ] || return 1
  [ -e ${JSN_MILESTONES} ] || return 1
  source <(sed -n '1,/-->/p' ${ISSUE_FILE} | sed '1d;$d')
  $verbose && echo "INFO! - *ISSUE_TITLE*: [ ${ISSUE_TITLE} ]"
  $verbose && echo "INFO! - *ISSUE_LABEL*: [ ${ISSUE_LABEL} ]"
  ISSUE_LABEL_NAME=$(echo $(<${JSN_LABELS}) | jq ".[] | select(.name == \"${ISSUE_LABEL}\") | .name ")
  ISSUE_LABEL_COLOR=$(echo $(<${JSN_LABELS}) | jq ".[] | select(.name == \"${ISSUE_LABEL}\") | .color ")
  $verbose && echo "INFO! - *ISSUE_LABEL_NAME*: [ ${ISSUE_LABEL_NAME} ]"
  $verbose && echo "INFO! - *ISSUE_LABEL_COLOR*: [ ${ISSUE_LABEL_COLOR} ]"
  ISSUE_MILESTONE_NUMBER=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .number" )
  ISSUE_MILESTONE_TITLE=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .title" )
  ISSUE_MILESTONE_DESCRIPTION=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .description" )
  $verbose && echo "INFO! - *ISSUE_MILESTONE_NUMBER*: [ ${ISSUE_MILESTONE_NUMBER} ]"
  $verbose &&  echo "INFO! - *ISSUE_MILESTONE_TITLE*: [ ${ISSUE_MILESTONE_TITLE} ]"
  $verbose &&  echo "INFO! - *ISSUE_MILESTONE_DESCRIPTION*: [ ${ISSUE_MILESTONE_DESCRIPTION} ]"
  ISSUE_BODY="$( branchEchoIssueBody )"
  ISSUE_SUMMARY="$( branchEchoIssueSummary )"
  $verbose &&  echo "INFO! - *ISSUE_SUMMARY*: [ ${ISSUE_SUMMARY} ]"
  # parseIntoArrayTaskList 'ISSUE_TASK_LIST'
  # parseIntoArrayFinishedTasks 'ISSUE_FINISHED_TASKS'
  # parseIntoArrayUnfinishedTasks 'ISSUE_UNFINISHED_TASKS'
}

function parseIssuePayload(){
if [ -e "${ISSUE_FILE}" ] ; then
  echo "CHECK! this projects ISSUE_FILE"
  # front-matter as a source
  source <(sed -n '1,/-->/p' ${ISSUE_FILE} | sed '1d;$d')

# check format
  # these 3 are created upon createIssue function
  echo "INFO! - *ISSUE_LABEL*: [ ${ISSUE_LABEL} ]"
  echo "INFO! - *ISSUE_TITLE*: [ ${ISSUE_TITLE} ]"
  echo "INFO! - *ISSUE_MILESTONE*: [ ${ISSUE_MILESTONE} ]"
  echo "ISSUE NUMBER is generated by github after new issue created"
  echo "INFO! - *ISSUE_NUMBER*: [ ${ISSUE_NUMBER} ] "
  # these below are created after a posting new issue to github
  echo "INFO! - *ISSUE_DATE*: [ ${ISSUE_DATE} ] "
  echo "INFO! - *ISSUE_STATE*: [ ${ISSUE_STATE} ] "
  echo "INFO! - *ISSUE_COMMENTS*: [ ${ISSUE_COMMENTS} ] "
fi
}


function branchEchoIssueBody(){
local lc=$( sed -n '1,/-->/p'  ${ISSUE_FILE} |  wc -l )
echo "$( sed "1,${lc}d;$d" ${ISSUE_FILE} )"
}

function branchEchoIssueSummary(){
local lineCount=$( sed -n '1,/-->/p'  ${ISSUE_FILE} |  wc -l )
echo "$( sed "1,${lineCount}d;$d" ${ISSUE_FILE} | head -n1 )"
}

function parseIntoArrayLabels(){
  $verbose && echo 'parse into array labels'
  LABELS=( $(echo "$(<${JSN_LABELS})"  | jq -r '.[] | .name  | @sh') ) 
  $verbose && for item in "${LABELS[@]}"; do echo "label [ ${item} ] "; done
}

function parseIntoArrayTaskList(){
grep -oP '^\-\s\[.\]\s\K.+$' ${ISSUE_FILE} > $TEMP_FILE
readarray ISSUE_TASK_LIST < $TEMP_FILE
echo "INFO! - a total of *${#ISSUE_TASK_LIST[@]}*  tasks in ISSUE_TASK_LIST"
}

function parseIntoArrayUnfinishedTasks(){
grep -oP '^\-\s\[\s\]\s\K.+$' ${ISSUE_FILE} > $TEMP_FILE
readarray ISSUE_UNFINISHED_TASKS < $TEMP_FILE
echo "INFO! - *${#ISSUE_UNFINISHED_TASKS[@]}* \
unfinished tasks in *ISSUE_UNFINISHED_TASKS*"
}

function parseIntoArrayFinishedTasks(){
grep -oP '^\-\s\[x\]\s\K.+$' ${ISSUE_FILE} > $TEMP_FILE
readarray ISSUE_FINISHED_TASKS < $TEMP_FILE
echo "INFO! - *${#ISSUE_FINISHED_TASKS[@]}* \
finished tasks in *ISSUE_FINISHED_TASKS*"
}

function parseIntoArrayCommitsHash(){
git log \
 --oneline  \
 --format=%h \
 $(git merge-base HEAD master)..${CURRENT_BRANCH}\
 > $TEMP_FILE
readarray COMMITS_HASH < $TEMP_FILE
}

function parseIntoArrayCommitsSubject(){
git log \
 --oneline  \
 --format=%s \
 $(git merge-base HEAD master)..${CURRENT_BRANCH}\
 > $TEMP_COMMITS_SUBJECTS
readarray COMMITS_SUBJECT < $TEMP_COMMITS_SUBJECTS
}

function parseRepo(){
[ ! -e "${JSN_REPO}" ] && return 1
#echo "TASK! PARSE REPO"
jsnFile="$(parseIntoNodeFS ${JSN_REPO})"
nSTR="J = require('${jsnFile}');\
  console.log('REPO_URL=' + J.url);\
  console.log('REPO_NAME=' + J.name);\
  console.log('REPO_FULL_NAME=' + J.full_name);\
  console.log('REPO_DESCRIPTION=\"' + J.description + '\"');\
  console.log('REPO_HOMEPAGE=' + J.homepage);\
  console.log('REPO_TAGS_URL=' + J.tags_url);\
  console.log('REPO_BRANCHES_URL=' +  J.branches_url.split('{')[0]);\
  console.log('REPO_ISSUES_URL=' +  J.issues_url.split('{')[0]);\
  console.log('REPO_LABELS_URL=' +  J.labels_url.split('{')[0]);\
  console.log('REPO_MILESTONES_URL=' +  J.milestones_url.split('{')[0]);\
  console.log('REPO_PULLS_URL=' +  J.pulls_url.split('{')[0]);\
  console.log('REPO_GIT_REFS_URL=' +  J.git_refs_url.split('{')[0]);\
  console.log('REPO_RELEASES_URL=' +  J.releases_url.split('{')[0]);\
  console.log('REPO_COMMITS_URL=' +  J.commits_url.split('{')[0]);\
  console.log('REPO_COMMENTS_URL=' +  J.comments_url.split('{')[0]);\
  console.log('REPO_ISSUE_COMMENT_URL=' +  J.issue_comment_url.split('{')[0]);\
  console.log('REPO_COMPARE_URL=' +  J.compare_url.split('{')[0]);\
  console.log('REPO_HTML_URL=' +  J.html_url.split('{')[0]);\
"
source <(node -e "${nSTR}")
}

function parsePullRequest(){
[ ! -e "${JSN_PULL_REQUEST}" ] && return 1
local jsnFile="$(parseIntoNodeFS ${JSN_PULL_REQUEST})"
local nSTR="J = require('${jsnFile}');\
  console.log('PR_URL=' + J.url);\
  console.log('PR_COMMITS_URL=' + J.commits_url);\
  console.log('PR_REVIEW_COMMENTS_URL=' + J.review_comments_url);\
  console.log('PR_COMMENTS_URL=' + J.comments_url);\
  console.log('PR_STATUSES_URL=' + J.statuses_url);\
  console.log('PR_NUMBER=' + J.number);\
  console.log('PR_TITLE=\'' + J.title + '\'');\
  console.log('PR_BODY=\'' + J.body + '\'');\
  console.log('PR_STATE=' + J.state);\
  console.log('PR_LOCKED=' + J.locked);\
  console.log('PR_MERGED=' + J.merged);\
  console.log('PR_MERGEABLE=' + J.mergeable);\
  console.log('PR_MERGEABLE_STATE=' + J.mergeable_state);\
  console.log('PR_HEAD_SHA=' + J.head.sha);\
  console.log('PR_HEAD_REF=' + J.head.ref);\
  console.log('PR_HEAD_LABEL=' + J.head.ref);\
  console.log('PR_BASE_SHA=' + J.base.sha);\
  console.log('PR_BASE_REF=' + J.base.ref);\
  console.log('PR_BASE_LABEL=' + J.base.ref);\
  console.log('PR_COMBINED_STATUS_URL=${REPO_COMMITS_URL}/' + J.head.sha + '/status');\
  console.log('PR_COMMENTS=' + J.comments);\
  console.log('PR_REVIEW_COMMENTS=' + J.review_comments);\
  console.log('PR_MILESTONE_NUMBER=' + J.milestone.number);\
  console.log('PR_MILESTONE_TITLE=\'' + J.milestone.title + '\'');\
  console.log('PR_MILESTONE_DESCRIPTION=\'' + J.milestone.description + '\'');\
"
$verbose && node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
source <(node -e "${nSTR}")
}


function parseCombinedStatus(){
if [ ! -e "${JSN_PR_COMBINED_STATUS}" ] ; then
  echo "FAILURE: file required ${JSN_PR_COMBINED_STATUS}"
  return 1
fi
local jsnFile="$( parseIntoNodeFS ${JSN_PR_COMBINED_STATUS} )"
local nSTR="J = require('${jsnFile}');\
  console.log('PR_COMBINED_STATUS_STATE=' + J.state);\
  console.log('PR_COMBINED_STATUS_TOTAL_COUNT=' + J.total_count);\
"
source <(node -e "${nSTR}")
echo "INFO! - *PR_COMBINED_STATUS_STATE*: [ ${PR_COMBINED_STATUS_STATE} ]"
echo "INFO! - *PR_COMBINED_STATUS_TOTAL_COUNT*: [ ${PR_COMBINED_STATUS_TOTAL_COUNT} ]"
}


function parseLatestRelease(){
[ ! -e "${JSN_LATEST_RELEASE}" ] && return 1
local jsnFile="$(parseIntoNodeFS ${JSN_LATEST_RELEASE})"
local nSTR="J = require('${jsnFile}');\
  console.log('RELEASE_URL=' + J.url);\
  console.log('RELEASE_NAME=' + J.name);\
  console.log('RELEASE_TAG_NAME=' + J.tag_name);\
  console.log('RELEASE_UPLOAD_URL=' + J.upload_url.split('{')[0] );\
  console.log('RELEASE_ID=' + J.id);\
  console.log('RELEASE_BODY=\"' + J.body + '\"');\
  console.log('TARBALL_URL=' + J.tarball_url);\
  console.log('ZIPBALL_URL=' + J.zipball_url);\
  if (J.assets.length ) { \
    console.log('RELEASE_ASSET_COUNT=' + J.assets.length);\
    console.log('ASSET_NAME=' + J.assets[0].name);\
    console.log('ASSET_LABEL=' + J.assets[0].label);\
    console.log('ASSET_CONTENT_TYPE=' + J.assets[0].content_type);\
    console.log('ASSET_STATE=' + J.assets[0].state);\
    console.log('ASSET_SIZE=' + J.assets[0].size);\
    console.log('ASSET_DOWNLOAD_COUNT=' + J.assets[0].download_count);\
    console.log('ASSET_CREATED_AT=' + J.assets[0].created_at);\
    console.log('ASSET_UPDATED_AT=' + J.assets[0].updated_at);\
    console.log('ASSET_BROWSER_DOWNLOAD_URL=' + J.assets[0].browser_download_url);\
    console.log('ASSET_UPLOADER=' + J.assets[0].uploader.login);\
  }\
"
$verbose && node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
# set -a
source <(node -e "${nSTR}")
# set +a

#=
#ZIPBALL_URL=
#BODY=
#CONTENT_TYPE=
#STATE=
#SIZE=
#DOWNLOAD_COUNT=
#BROWSER_DOWNLOAD_URL=


return 0
# if [ ! -e "${JSN_LATEST_RELEASE}" ] ; then
#   echo "FAILURE: file required ${JSN_LATEST_RELEASE}"
#   return 1
# fi
# RELEASE_UPLOAD_URL=
#HTML_URL=
# RELEASE_TAG_NAME=
#TARGET_COMMITISH=
# RELEASE_NAME=
#TARBALL_URL=
#ZIPBALL_URL=
#BODY=
#CONTENT_TYPE=
#STATE=
#SIZE=
#DOWNLOAD_COUNT=
#BROWSER_DOWNLOAD_URL=



}




function parseAssetUploaded(){
ASSET_URL=
ASSET_BROWSER_DOWNLOAD_URL=
ASSET_NAME=
#CONTENT_TYPE=
#STATE=
#SIZE=
#LABEL=
#DOWNLOAD_COUNT=
#BROWSER_DOWNLOAD_URL=

local jsnFile="$(parseIntoNodeFS ${JSN_ASSET_UPLOADED})"
local nSTR="J = require('${jsnFile}');\
 R = require('ramda');\
 j = R.pick([\
 'browser_download_url','url','name'
 ],J);\
 browser_download_url = 'ASSET_BROWSER_DOWNLOAD_URL=' + R.prop('browser_download_url',j);\
 url = 'ASSET_URL=' + R.prop('url',j);\
 name = 'ASSET_NAME=' + R.prop('name',j);\
 print = function(x){console.log(x)};\
 R.forEach(print, [\
 browser_download_url,\
 url, \
 name
 ]);\
"
#node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
source <(node -e "${nSTR}")

echo "INFO! - *ASSET_URL*: [ ${ASSET_URL} ]"
echo "INFO! - *ASSET_BROWSER_DOWNLOAD_URL*: [ ${ASSET_BROWSER_DOWNLOAD_URL} ]"
echo "INFO! - *ASSET_NAME*: [ ${ASSET_NAME} ]"
}

function parseMerged(){
if [ ! -e "${JSN_PR_MERGE}" ] ; then
  echo "FAILURE: file required ${JSN_PR_MERGE}"
  return 1
fi
local jsnFile="$( parseIntoNodeFS ${JSN_PR_MERGE} )"
nSTR="J = require('${jsnFile}');\
 R = require('ramda');\
 j = R.pick([\
 'merged','message'
 ],J);\
 merged = 'MERGE_MERGED=' + R.prop('merged',j);\
 message = 'MERGE_MESSAGE=\"' + R.prop('message',j) + '\"';\
 print = function(x){console.log(x)};\
 R.forEach(print, [
 merged,\
 message
 ]);\
"
source <(node -e "${nSTR}")
#node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
echo "INFO! - *MERGE_MERGED*: [ ${MERGE_MERGED} ]"
echo "INFO! - *MERGE_MESSAGE*: [ ${MERGE_MESSAGE} ]"
}

