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
echo "$1"
local branchName="${1}"
if [ -z "${branchName}" ] ; then
 branchName="${CURRENT_BRANCH}"
fi

PARSED_ISSUE_LABEL=
PARSED_ISSUE_NUMBER=
PARSED_ISSUE_TITLE=
echo "INFO! topic branch-name can be parsed into LABEL NUMBER TITLE"
echo "INFO! *branch-name* [ ${branchName} ]"
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
        echo "INFO! - *PARSED_ISSUE_LABEL*: [ ${PARSED_ISSUE_LABEL} ]"
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
         echo "INFO! - *PARSED_ISSUE_NUMBER*: [ ${PARSED_ISSUE_NUMBER} ]"
    else
        echo "FAILURE! ${msg} : PARSED_ISSUE_NUMBER"
       return 1 
    fi 
fi

if [ -z "${PARSED_ISSUE_TITLE}" ] ; then
    echo "FAILURE! ${msg} : PARSED_ISSUE_TITLE"
    return 1  
else
     echo "INFO! - *PARSED_ISSUE_TITLE*: [ ${PARSED_ISSUE_TITLE} ]"
fi 
}

function parseTags(){
jsnTAGS=$(<${JSN_TAGS})
LATEST_TAG="$(
echo "${jsnTAGS}" |
jq -r -c '.[0] | .name '
)"
echo "INFO! - *LATEST_TAG*: [ ${LATEST_TAG} ]"
}

function parseFetchedIssues(){
if [ ! -e "${JSN_ISSUES}" ] ; then
  echo "FAILURE: file required ${JSN_ISSUES}"
  return 1
fi
#echo "TASK! get issues from github that can become branches"
## note param is label not labels
## https://developer.github.com/v3/issues/
## if issues list gets to big use more filters e.g. state and since
#local URL="${REPO_ISSUES_URL}?label=${labels}"
#repoFetch ${URL} ${GITHUB_ISSUES} || return 1
ISSUES_COUNT=$(
 node -pe "J = require('${GITHUB_ISSUES}');\
 R = require('ramda');\
 R.length(J)"
 )
echo "INFO! - *ISSUES_COUNT*: [ ${ISSUES_COUNT} ]"

nSTR="J = require('$( parseIntoNodeFS ${JSN_ISSUES} )');\
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
node -e "${nSTR}" | R -o table 'project [\number \label \title \state \milestone_title]'
}


function parseIntoArrayIssuesForBranches(){
if [ ! -e "${JSN_ISSUES}" ] ; then
  echo "FAILURE: file required ${JSN_ISSUES}"
  return 1
fi
nSTR="J = require('${GITHUB_ISSUES}');\
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
node -e "${nSTR}" | R -pS 'id'
IFS=$'\n\r'
readarray ISSUES_FOR_BRANCHES <<< "$(node -e "${nSTR}" | R -S 'id')"
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
if [ ! -e "${JSN_ISSUE}" ] ; then
  echo "FAILURE: file required ${JSN_ISSUE}"
  return 1
fi
local jsnFile="$(parseIntoNodeFS ${JSN_ISSUE})"
local nSTR=
ISSUE_PULLS_URL=
if [ -z "$(node -pe "require('${jsnFile}')['pull_request']" | grep -oP 'undefined')" ]
 then
 ISSUE_PULLS_URL="$(node -pe "require('${jsnFile}')['pull_request']['url']")"
fi
# echo "$(<${JSN_ISSUE})" | jq '.'
nSTR="J = require('${jsnFile}');\
 R = require('ramda');\
 j = R.pick([\
 'url', 'comments_url', 'events_url',\
 'title','number', 'labels', 'milestone' , 'state', 'updated_at',\
 'comments', 'body'\
 ],J);\
 url = 'FETCHED_URL=' + R.prop('url',j);\
 events_url = 'FETCHED_EVENTS_URL=' + R.prop('events_url',j);\
 comments_url = 'FETCHED_COMMENTS_URL=' + R.prop('comments_url',j);\
 title = 'FETCHED_ISSUE_TITLE=\"' + R.prop('title',j) + '\"';\
 number = 'FETCHED_ISSUE_NUMBER=' + R.prop('number',j);\
 milestone_title = 'FETCHED_ISSUE_MILESTONE_TITLE=' + R.prop('milestone',j)['title'];\
 milestone_number = 'FETCHED_ISSUE_MILESTONE_NUMBER=' + R.prop('milestone',j)['number'];\
 label = 'FETCHED_ISSUE_LABEL=' + R.prop('labels',j)[0].name;\
 state = 'FETCHED_ISSUE_STATE=' + R.prop('state',j);\
 updated_at = 'FETCHED_ISSUE_UPDATED_AT=' + R.prop('updated_at',j);\
 comments = 'FETCHED_ISSUE_COMMENTS=' + R.prop('comments',j);\
 body = 'FETCHED_ISSUE_BODY=\"' + R.prop('body',j) + '\"';\
 print = function(x){console.log(x)};\
 R.forEach(print, \
 [url, comments_url, events_url, title, number, milestone_title ,\
 milestone_number, label , state, updated_at, comments,
 body ]);\
"
# node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
source <(node -e "${nSTR}")
# TODO! double check parsed branch-name with ... below
# echo "INFO! - *FETCHED_URL*: [ ${FETCHED_URL} ]"
# echo "INFO! - *FETCHED_EVENTS_URL* : [ ${FETCHED_EVENTS_URL} ]"
# echo "INFO! - *FETCHED_COMMENTS_URL* : [ ${FETCHED_COMMENTS_URL} ]"
# echo "INFO! - *FETCHED_ISSUE_UPDATED_AT*: [ ${FETCHED_ISSUE_UPDATED_AT} ]"
# echo "INFO! - *FETCHED_ISSUE_LABEL*: [ ${FETCHED_ISSUE_LABEL} ]"
# echo "INFO! - *FETCHED_ISSUE_NUMBER*: [ ${FETCHED_ISSUE_NUMBER} ]"
# echo "INFO! - *FETCHED_ISSUE_TITLE*: [ ${FETCHED_ISSUE_TITLE} ]"
# echo "INFO! - *FETCHED_ISSUE_MILESTONE_TITLE*: [ ${FETCHED_ISSUE_MILESTONE_TITLE} ]"
# echo "INFO! - *FETCHED_ISSUE_MILESTONE_NUMBER*: [ ${FETCHED_ISSUE_MILESTONE_NUMBER} ]"
# echo "INFO! - *FETCHED_ISSUE_STATE*: [ ${FETCHED_ISSUE_STATE} ]"
# echo "INFO! - *FETCHED_ISSUE_COMMENTS*: [ ${FETCHED_ISSUE_COMMENTS} ]"
# echo "INFO! - *FETCHED_ISSUE_BODY* ... "
# echo "INFO! - *ISSUE_PULLS_URL* : [ ${ISSUE_PULLS_URL} ]"
# local fileTitle="$( echo "${FETCHED_ISSUE_TITLE}" | tr ' ' '-')"
# local toFile="${GITHUB_DIR}/issue/${FETCHED_ISSUE_LABEL}-${FETCHED_ISSUE_NUMBER}-${fileTitle}.json"
# cp ${JSN_ISSUE} ${toFile}
}


function parseIssueMD(){
  # front-matter as a source
  [ -e ${ISSUE_FILE} ] || return 1
  [ -e ${JSN_LABELS} ] || return 1
  [ -e ${JSN_MILESTONES} ] || return 1
  source <(sed -n '1,/-->/p' ${ISSUE_FILE} | sed '1d;$d')
  echo "INFO! - *ISSUE_TITLE*: [ ${ISSUE_TITLE} ]"
  echo "INFO! - *ISSUE_LABEL*: [ ${ISSUE_LABEL} ]"
  ISSUE_LABEL_NAME=$(echo $(<${JSN_LABELS}) | jq ".[] | select(.name == \"${ISSUE_LABEL}\") | .name ")
  ISSUE_LABEL_COLOR=$(echo $(<${JSN_LABELS}) | jq ".[] | select(.name == \"${ISSUE_LABEL}\") | .color ")
  echo "INFO! - *ISSUE_LABEL_NAME*: [ ${ISSUE_LABEL_NAME} ]"
  echo "INFO! - *ISSUE_LABEL_COLOR*: [ ${ISSUE_LABEL_COLOR} ]"
  ISSUE_MILESTONE_NUMBER=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .number" )
  ISSUE_MILESTONE_TITLE=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .title" )
  ISSUE_MILESTONE_DESCRIPTION=$(echo "$(<${JSN_MILESTONES})" | jq ".[]  | select(.title == \"${ISSUE_MILESTONE}\") | .description" )
  echo "INFO! - *ISSUE_MILESTONE_NUMBER*: [ ${ISSUE_MILESTONE_NUMBER} ]"
  echo "INFO! - *ISSUE_MILESTONE_TITLE*: [ ${ISSUE_MILESTONE_TITLE} ]"
  echo "INFO! - *ISSUE_MILESTONE_DESCRIPTION*: [ ${ISSUE_MILESTONE_DESCRIPTION} ]"
  ISSUE_BODY="$( branchEchoIssueBody )"
  ISSUE_SUMMARY="$( branchEchoIssueSummary )"
  echo "INFO! - *ISSUE_SUMMARY*: [ ${ISSUE_SUMMARY} ]"
  parseIntoArrayTaskList 'ISSUE_TASK_LIST'
  parseIntoArrayFinishedTasks 'ISSUE_FINISHED_TASKS'
  parseIntoArrayUnfinishedTasks 'ISSUE_UNFINISHED_TASKS'
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
  jsnLABELS=$(<${JSN_LABELS})
   echo "${jsnLABELS}" > $TEMP_FILE
  #echo "${jsnMILESTONES}" | jq -r -c '.[] | [ .title ] '
  #echo "${jsnMILESTONES}" | R -p  'identity'
IFS=$'\n\r'
readarray LABELS <<< $(echo "${jsnLABELS}" | R  'pluck \name' -o raw)
for item in  "${LABELS[@]}"
  do
	echo "${item}"
  done
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
nSTR="J = require('$( parseIntoNodeFS ${JSN_PULL_REQUEST} )');\
 R = require('ramda');\
 j = R.pick([\
 'html_url','title','number','milestone','state', 'commits' , 'updated_at',\
 'comments','review_comments','merged','mergeable','mergeable_state',\
 'body','head','base',\
 'url','commits_url', 'review_comments_url', 'comments_url', 'statuses_url'\
 ],J);\
 title = 'PR_TITLE=\"' + R.prop('title',j) + '\"';\
 number = 'PR_NUMBER=' + R.prop('number',j);\
 milestone_title = 'PR_MILESTONE_TITLE=' + R.prop('milestone',j)['title'];\
 milestone_number = 'PR_MILESTONE_NUMBER=' + R.prop('milestone',j)['number'];\
 state = 'PR_STATE=' + R.prop('state',j);\
 commits = 'PR_COMMITS=' + R.prop('commits',j);\
 updated_at = 'PR_UPDATED_AT=' + R.prop('updated_at',j);\
 comments = 'PR_COMMENTS=' + R.prop('comments',j);\
 review_comments = 'PR_REVIEW_COMMENTS=' + R.prop('review_comments',j);\
 merged = 'PR_MERGED=' + R.prop('merged',j);\
 mergeable = 'PR_MERGEABLE=' + R.prop('mergeable',j);\
 mergeable_state = 'PR_MERGEABLE_STATE=' + R.prop('mergeable_state',j);\
 body = 'PR_BODY=\"' + R.prop('body',j) + '\"';\
 head_sha =  'PR_HEAD_SHA=' + R.prop('head',j)['sha'];\
 head_ref =  'PR_HEAD_REF=' + R.prop('head',j)['ref'];\
 base_sha =  'PR_BASE_SHA=' + R.prop('base',j)['sha'];\
 base_ref =  'PR_BASE_REF=' + R.prop('base',j)['ref'];\
 url = 'PR_URL=' + R.prop('url',j);\
 commits_url = 'PR_COMMITS_URL=' + R.prop('commits_url',j);\
 statuses_url = 'PR_STATUSES_URL=' + R.prop('statuses_url',j);\
 review_comments_url = 'PR_REVIEW_COMMENTS_URL=' + R.prop('review_comments_url',j);\
 comments_url = 'PR_COMMENTS_URL=' + R.prop('comments_url',j);\
 html_url = 'PR_HTML_URL=' + R.prop('html_url',j);\
 print = function(x){console.log(x)};\
 R.forEach(print, [\
 title, \
 number, \
 milestone_title ,\
 milestone_number, \
 state, \
 commits, \
 updated_at, \
 comments, \
 review_comments, \
 merged, \
 mergeable, \
 mergeable_state, \
 body,\
 head_sha, head_ref, base_sha, base_ref, \
 url, commits_url, comments_url, review_comments_url, statuses_url, html_url
 ]);\
"
# debug with below
# node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
source <(node -e "${nSTR}")
}


function parseCombinedStatus(){
if [ ! -e "${JSN_PR_COMBINED_STATUS}" ] ; then
  echo "FAILURE: file required ${JSN_PR_COMBINED_STATUS}"
  return 1
fi
local jsnFile="$( parseIntoNodeFS ${JSN_PR_COMBINED_STATUS} )"
nSTR="J = require('${jsnFile}');\
 R = require('ramda');\
 j = R.pick([\
 'state'
 ],J);\
 state = 'PR_COMBINED_STATUS_STATE=' + R.prop('state',j);\
 print = function(x){console.log(x)};\
 R.forEach(print, [\
 state
 ]);\
"
source <(node -e "${nSTR}")
echo "INFO! - *PR_COMBINED_STATUS_STATE*: [ ${PR_COMBINED_STATUS_STATE} ]"
}

function parseRelease(){
RELEASE_UPLOAD_URL=
#HTML_URL=
RELEASE_TAG_NAME=
#TARGET_COMMITISH=
RELEASE_NAME=
#TARBALL_URL=
#ZIPBALL_URL=
#BODY=
#CONTENT_TYPE=
#STATE=
#SIZE=
#DOWNLOAD_COUNT=
#BROWSER_DOWNLOAD_URL=

nSTR="J = require('${GITHUB_RELEASE}');\
 R = require('ramda');\
 j = R.pick([\
 'upload_url','tag_name','name'
 ],J);\
 upload_url = 'RELEASE_UPLOAD_URL=' + \
  R.substringTo(R.strIndexOf('{',R.prop('upload_url',j)),R.prop('upload_url',j)) \
  + '?name=';\
 tag_name = 'RELEASE_TAG_NAME=' + R.prop('tag_name',j);\
 name = 'RELEASE_NAME=' + R.prop('name',j);\
 print = function(x){console.log(x)};\
 R.forEach(print, [\
 upload_url,\
 tag_name, \
 name
 ]);\
"

#node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
source <(node -e "${nSTR}")

echo "INFO! - *RELEASE_UPLOAD_URL*: [ ${RELEASE_UPLOAD_URL} ]"
echo "INFO! - *RELEASE_TAG_NAME*: [ ${RELEASE_TAG_NAME} ]"
echo "INFO! - *RELEASE_NAME*: [ ${RELEASE_NAME} ]"
 
}

function parseLatestRelease(){
[ ! -e "${JSN_LATEST_RELEASE}" ] && return 1
jsnFile="$(parseIntoNodeFS ${JSN_LATEST_RELEASE})"
nSTR="J = require('${jsnFile}');\
  console.log('RELEASE_URL=' + J.url);\
  console.log('RELEASE_NAME=' + J.name);\
  console.log('RELEASE_TAG_NAME=' + J.tag_name);\
  console.log('RELEASE_UPLOAD_URL=' + J.upload_url.split('{')[0] );\
  console.log('RELEASE_ID=' + J.id);\
  console.log('RELEASE_BODY=\"' + J.body + '\"');\
  if (J.assets.length ) { console.log('RELEASE_ASSET_COUNT=' + J.assets.length) }
"
source <(node -e "${nSTR}")
node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done

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

# local jsnFile="$( parseIntoNodeFS ${JSN_LATEST_RELEASE} )"

# nSTR="J = require('${jsnFile}');\
#  R = require('ramda');\
#  j = R.pick([\
#  'upload_url','tag_name','name'
#  ],J);\
#  upload_url = 'RELEASE_UPLOAD_URL=' + \
#   R.substringTo(R.strIndexOf('{',R.prop('upload_url',j)),R.prop('upload_url',j)) \
#   + '?name=';\
#  tag_name = 'RELEASE_TAG_NAME=' + R.prop('tag_name',j);\
#  name = 'RELEASE_NAME=' + R.prop('name',j);\
#  print = function(x){console.log(x)};\
#  R.forEach(print, [\
#  upload_url,\
#  tag_name, \
#  name
#  ]);\
# "

#node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done
# source <(node -e "${nSTR}")

# echo "INFO! - *RELEASE_UPLOAD_URL*: [ ${RELEASE_UPLOAD_URL} ]"
# echo "INFO! - *RELEASE_TAG_NAME*: [ ${RELEASE_TAG_NAME} ]"
# echo "INFO! - *RELEASE_NAME*: [ ${RELEASE_NAME} ]"
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

nSTR="J = require('${GITHUB_ASSET_UPLOADED}');\
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

