#!/bin/bash +x
###############

function prPriorPullRequest(){
  [ -e "${JSN_REPO}" ]  || exit 1
  [ -e "${JSN_ISSUE}" ] || exit 1
  [ -z "$( echo ${CURRENT_BRANCH} | grep -oP '^master$')" ] && {
   ON_MASTER='false'
   echo "INFO! - *ON_MASTER* [ ${ON_MASTER} ]"
   } || exit 1
[ -n "$( echo ${TERM})" ] && {
  IN_TERMINAL='true'
  echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
  } || {
  IN_TERMINAL='false'
  echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
  }

if [ -z "$(git status -s --porcelain)" ]  ; then
 echo "INFO! - *GIT_STATUS* [ 'clean' ]"
else
  git status -s --porcelain
  git commit -am 'prep for pull-request'
fi


if [ -e ${JSN_PULL_REQUEST} ] ; then
  PR_NUMBER="$(node -pe "require('${GITHUB_PULL_REQUEST}')['number']")"
  echo "INFO! - PR_NUMBER [ ${PR_NUMBER} ]"
  [ ${PR_NUMBER} -ne ${FETCHED_ISSUE_NUMBER} ] && {
   etagFile=$(parseIntoETAG ${JSN_PULL_REQUEST})
   headerFile=$(parseIntoHEADER ${JSN_PULL_REQUEST})
  if [ -e ${etagFile} ] ; then
    echo "TASK! - remove [  ${etagFile} ]"
    rm ${etagFile}
  fi
  if [ -e ${headerFile} ] ; then
    echo "TASK! - remove [  ${headerFile} ]"
    rm ${headerFile}
  fi
  }
fi

fileARR=(
  ${JSN_PR_COMMENT}
  ${JSN_PR_COMMENTS}
  ${JSN_PR_COMMITS}
  ${JSN_PR_STATUSES}
  ${JSN_PR_COMBINED_STATUS}
  ${JSN_PR_MERGE}
)

for fileItem in "${fileARR[@]}"
do
  etagFile=$(parseIntoETAG ${fileItem})
  headerFile=$(parseIntoHEADER ${fileItem})
  if [ -e ${fileItem} ] ; then
    echo "TASK! - remove [  ${fileItem} ]"
    rm ${fileItem}
  fi
  if [ -e ${etagFile} ] ; then
    echo "TASK! - remove [  ${etagFile} ]"
    rm ${etagFile}
  fi
  if [ -e ${headerFile} ] ; then
    echo "TASK! - remove [  ${headerFile} ]"
    rm ${headerFile}
  fi
done

parseFetchedIssue > /dev/null
#echo "INFO! - *ISSUE_PULLS_URL* [ ${ISSUE_PULLS_URL} ]"
if [ -z "${ISSUE_PULLS_URL}" ] ; then
   echo "CHECK! - fetched issue has no pulls url [  'OK!' ]"
else
   echo "CHECK! - issue pulls url [  'FAIL!' ]"
   return 1
fi

needPush=$( git status | grep 'Your branch is ahead of' )

if [ -z "${needPush}" ] ; then
   echo "CHECK! - no push required[  'OK!' ]"
else
   echo "CHECK! - push required [  'FAIL!' ]"
   echo "INFO! - push required [  ${needPush} ]"
   prPushToRemote
fi
echo "INFO! conditions met.. move on"
}

function prLists(){
  PR_LISTS=( commits comments combined-status statuses commits)
  for item in "${PR_LISTS[@]}";
  do
  gh get-pr-$item
  done
  gh get-pulls
}

function prTasks(){

  #conditions
[ -e "${JSN_REPO}" ]  || exit 1
[ -e "${JSN_ISSUE}" ] || exit 1
[ -z "$( echo ${CURRENT_BRANCH} | grep -oP '^master$')" ] && {
   ON_MASTER='false'
   echo "INFO! - *ON_MASTER* [ ${ON_MASTER} ]"
   } || exit 1
[ -n "$( echo ${TERM})" ] && {
  IN_TERMINAL='true'
  echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
  } || {
  IN_TERMINAL='false'
  echo "INFO! - *IN_TERMINAL* [ ${IN_TERMINAL} ]"
  }

if [ -z "$(git status -s --porcelain)" ]  ; then
 echo 'repo clean'
else
  git status -s --porcelain
  git commit -am 'prep for pull-request'
fi

#GITHUB_ISSUE="$( parseIntoNodeFS ${JSN_ISSUE} )"
#echo "INFO! - GITHUB_ISSUE [ ${GITHUB_ISSUE} ]"
#ISSUE_NUMBER="$(node -pe "require('${GITHUB_ISSUE}')['number']")"
parseFetchedIssue || return 1
echo "INFO! - CURRENT_BRANCH [ ${CURRENT_BRANCH} ]"
local etagFile=
#tear down
# TODO! rm
if [ -e ${JSN_PULL_REQUEST} ] ; then
  PR_NUMBER="$(node -pe "require('${GITHUB_PULL_REQUEST}')['number']")"
  echo "INFO! - PR_NUMBER [ ${PR_NUMBER} ]"
  [ ${PR_NUMBER} -ne ${FETCHED_ISSUE_NUMBER} ] && {
   etagFile=$(parseIntoETAG ${JSN_PULL_REQUEST})
   rm ${JSN_PULL_REQUEST}
   rm ${etagFile}
   }
  [ -e ${JSN_PR_STATUSES} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_STATUSES})
    rm ${JSN_PR_STATUSES}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMITS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMITS})
    rm ${JSN_PR_COMMITS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_STATUS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_STATUS})
    rm ${JSN_PR_STATUS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMENTS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMENTS})
    rm ${JSN_PR_COMMENTS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMENT} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMENT})
    rm ${JSN_PR_COMMENT}
    rm ${etagFile}
   }
  [ -e ${JSN_MERGE} ] && {
    etagFile=$(parseIntoETAG ${JSN_MERGE})
    rm ${JSN_MERGE}
    rm ${etagFile}
    }
fi
echo "INFO! conditions met.. move on"
#parseRepo || return 1
#exit
#repoFetch ${ISSUE_PULLS_URL} ${GITHUB_PULL_REQUEST} || return 1
echo "CHECK! - for pull request file"
if [ ! -e  ${JSN_PULL_REQUEST} ] ; then
  echo "NOPE! - do not have pull request file"
  echo "NOTE! - if we already have a pull-request then \
  JSN_ISSUE will have the pull_request"
  if [ -z "${ISSUE_PULLS_URL}" ] ; then
	echo "TASK! create new PULL_REQUEST"
	prPushToRemote || return 1
	gh create-pull-request "{FETCHED_ISSUE_NUMBER}" || return 1
    gh get-issue "${FETCHED_ISSUE_NUMBER}" || return 1
	[ -e  ${JSN_PULL_REQUEST} ] || return 1
	echo "TASK! PULL_REQUEST created"
  else
	echo "TASK! fetch existing PULL_REQUEST"
    repoFetch ${ISSUE_PULLS_URL} ${JSN_PULL_REQUEST} || return 1
	#[ -e  ${JSN_PULL_REQUEST} ] || return 1
	echo "TASK! fetch existing PULL_REQUEST fetched and stored"
  fi
else
   echo "YEP! - have request file"
fi

#[ -e  ${JSN_PULL_REQUEST} ] || return 1
parsePullRequest  || return 1
#fetch updated ver
#TODO!
repoFetch ${PR_URL} ${JSN_PULL_REQUEST} || return 1
parsePullRequest  || return 1
if [ "${PR_COMMENTS}" -eq 0 ] ; then
  [ -e ${JSN_PR_COMMENTS} ] && rm ${JSN_PR_COMMENTS}
  [ -e ${JSN_PR_COMMENT} ] && rm ${JSN_PR_COMMENT}
  prFirstComment || return 1
  repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}" || return 1
  if [ "${AUTOMATE_PULL_REQUEST}" = 'true' ] ;then
	echo "INFO! STAGE 1 *AUTOMATE_PULL_REQUEST* [ ${AUTOMATE_PULL_REQUEST} ]"
	repoFetch ${PR_URL} ${JSN_PULL_REQUEST} || return 1
	parsePullRequest  || return 1
  fi
fi

if [[ "${PR_REVIEW_COMMENTS}" -gt 0 ]] ; then
   if ! prReviewCommentTasks ; then
	   exit
   fi
fi

# comments PR_COMMENTS_URL get all comments with text
if [ ! -e ${JSN_PR_COMMENTS} ] ; then
  echo "TASK! fetch pull-request_comments"
  repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}" || return 1
  echo "DONE! fetched pull-request_comments"
fi
PR_COMMENTS_COUNT=$(
  node -pe "require('${GITHUB_PR_COMMENTS}').length"
  )
echo "INFO! *PR_COMMENTS_COUNT* [ ${PR_COMMENTS_COUNT} ]"
echo "INFO! *PR_COMMENTS* [ ${PR_COMMENTS} ]"
if [ ${PR_COMMENTS_COUNT} -ne  ${PR_COMMENTS} ] ; then
  echo "YEP!  more comments to get"
  repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}"
fi

echo "INFO! - show all comments"
nSTR="\
R=require('ramda');\
print = function(x){console.log(x)};\
R.forEach( print, R.pluck('body',require('./.github/pr-comments.json')))"
node -e "${nSTR}" | while IFS= read -r line; do echo "$line"; done

echo "CHECK! if has shipit comment"
hasShipIt=$(
  node -e "${nSTR}" |
  grep -oP ':shipit:'
  )
  
if [ -n "${hasShipIt}" ] ; then
 echo "YEP! - has ${hasShipIt} comment"
  prMergeableStateTasks  || return 1
else
 echo "NOPE! - does *not* have shipit comment"
  prApproval  || return 1
  if [ "${AUTOMATE_PULL_REQUEST}" = 'true' ] ;then
	echo "INFO! STAGE 2 *AUTOMATE_PULL_REQUEST* [ ${AUTOMATE_PULL_REQUEST} ]"
	repoFetch ${PR_URL} ${JSN_PULL_REQUEST} || return 1
	parsePullRequest  || return 1
	repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}" || return 1
	prMergeableStateTasks  || return 1
  fi
fi

#
return
}
## after initial pull request, my code is public
##  we are expecting reviews, comments and integration tests before
##  branch is merged into master and then deployed
#
##STEPS:
## GitHub Pull Request Review Comments API, the comments are on a different
## portion of the unified diff
## my understanding is that review comments refer to commits
##  if someones sees something that needs fixing re the commit then the comment
##  will reference the commit
##  this is saying,
##  'consider this, if code needs changing
##  add unfinished item to the todo list explaining change required
##  rewrite, commit again'
##1  TODO!

## 2
##  take  look at the comments around the pr
##  make sure some human has approved pull request with a shipit coment
##  then examine the mergable state of the pr
##  make sure the machines have done there pre-merge checks (linted, tested etc)
##  and delivered a success verdict for each context
##    TODO!

#function prPriorTasks(){
#echo "TASK! tasks before making pull request"
## step 1
#echo "TASK! reviewed and cleaned up commits before push"
#echo "TODO! "
#echo "DONE! - reviewed and cleaned up commits before push"
## step 2  update
#    #echo "TASK! - update origin/ branches from remote repo"
#    #doTask=$( git fetch origin )
#    #echo "DONE! - *updated* origin/ branches from remote repo"
## step 3  clean up commit history
##http://chrismar035.com/2013/04/04/better-pull-requests-with-autosquash
##So when I use git rebase, I (almost) always give it two arguments: the name of
##the place I want to start from, and the name of the place I want to end up
## git rebase <base> <target>
#  #echo "TASK! - rebase from where diverged from master"
#  #doTask=$(
#  #git rebase --autosquash $(git merge-base HEAD master) ${CURRENT_BRANCH}

# git rebase --autosquash $(git merge-base HEAD master) $(git symbolic-ref HEAD 2> /dev/null | sed -e 's/refs\/heads\///')

function prPushToRemote(){
echo "CHECK! if local branch up to date with origin"
  doTask=$(
  git push origin ${CURRENT_BRANCH} --dry-run  --porcelain |
  grep -oP 'up to date'
  )
if [ -n "${doTask}" ] ; then
  echo "YEP! ${doTask}"
  return 0
else
  echo "NOPE! - ..."
  echo "TASK! push local branch to origin/${CURRENT_BRANCH}"
  doTask=$(
	git push origin ${CURRENT_BRANCH} --porcelain
	)
  echo "INFO! ${doTask}"
  echo "DONE! *pushed* local branch to origin/${CURRENT_BRANCH}"
  return 0
fi
}

#function prCreatePR(){
##When we think the branch is ready for merging into master.
## We [create a pull
##request](https://developer.github.com/v3/pulls/#create-a-pull-request). Every
##pull request is an issue so we use our issue number. The code is now open for
##testing, review and comment.
##jsn="{'tag_name':'${1}','target_commitish':'master','name':'${2}','body':${3},'draft':false,'prerelease':false}"
##echo "TASK! create pull request based on issue number"
##jsn=$(cat << EOF
##{
##"issue": "${ISSUE_NUMBER}",
##"head": "${CURRENT_BRANCH}",
##"base": "master"
##} 
##EOF
##)
###echo "${REPO_PULLS_URL}"
###echo "${GITHUB_PULL_REQUEST}"
###echo "${jsn}" | jq '.'
##if repoCreate "${REPO_PULLS_URL}" "${JSN_PULL_REQUEST}" "${jsn}" ;then
##	echo "OK! pull request created"
##	echo "INFO! the code is now open for testing, review and comment"
##	return 0
##else
##	return 1
##fi
#}
#
function prFirstComment(){   
#https://github.com/blog/612-introducing-github-compare-view
#echo "INFO! -  '
#echo "INFO! - to see what changes are proposed '
#echoLine
#echo "${REPO_HTML_URL}/compare/${PR_BASE_SHA}...${PR_HEAD_SHA}"
###w3m "${REPO_HTML_URL}/compare/${PR_BASE_SHA}...${PR_HEAD_SHA}"
#echoLine
echo "TASK! post first comment with short compare url from git.io"
PR_COMMENTS_URL=$(
 node -pe "require('${GITHUB_PULL_REQUEST}')['comments_url']"
 )

echo "INFO! *PR_COMMENTS_URL*: [${PR_COMMENTS_URL}]"
LONG_URL="${REPO_HTML_URL}/compare/${PR_BASE_SHA}...${PR_HEAD_SHA}"
echo "${LONG_URL}"
repoShortUrl
PR_SHORT_COMPARE_URL="${SHORT_URL}"
echo "INFO! - *PR_SHORT_COMPARE_URL*: [ ${PR_SHORT_COMPARE_URL} ]" 
jsn=$(       
cat << EOF | jq -s -R '.' | jq '{body: .}'
you might want to take a look at the  to see what changes are
proposed at the [compare URL]( ${PR_SORT_COMPARE_URL} )
EOF
)
if repoCreate "${PR_COMMENTS_URL}" "${JSN_PR_COMMENT}" "${jsn}" ; then
  echo "DONE! posted first comment short compare url"
  echo "INFO! - *PR_SHORT_COMPARE_URL* [ ${PR_SHORT_COMPARE_URL} ]"
fi

echo "INFO! be part of the conversation around this pull request visit"
echo "INFO! - *PR_HTML_URL* [ ${PR_HTML_URL} ]"
}
#
#
#
function prReviewCommentTasks(){
echo 'TODO! prReviewCommentTasks'
return 0
}
#
function prCommentTasks(){
echo "INFO! someone has commented on pull-request"
#TODO!
#TODO! create status report for each comment
# a-human-has-looked-at-this/first-comment
# approved-by/owner 
PR_COMMENTS_URL=$(
 node -pe "require('${GITHUB_PULL_REQUEST}')['comments_url']"
 )
echo "TASK! fetch pull request_comments"
if [ -e ${JSN_PR_COMMENTS} ] ; then
  echo "CHECK!  since last fetch are there more comments to get"
  jsnPR_COMMENTS=$(cat $JSN_PR_COMMENTS | jq '.')
  arrayLength=$( echo "${jsnPR_COMMENTS}" | jq '. | length')
  if [ "${arrayLength}" -ne  "${PR_COMMENTS}" ] ; then
    echo "YEP!  more comments to get"
    repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}" || return 1
    #recurse
    prTasks || return 1
  else
    echo "NOPE!  no more comments to get OK!"
    return 0
  fi   
else
  repoFetch "${PR_COMMENTS_URL}" "${JSN_PR_COMMENTS}" || return 1
  #recurse
  prTasks || return 1
fi
}
#
#
function prApproval(){
jsnPR_COMMENTS="$( cat "${JSN_PR_COMMENTS}" | jq '.' )"
echo "INFO! - PULL REQUEST COMMENTS"
echo "${jsnPR_COMMENTS}" | jq '.[].body'
chkApproved="$( echo "${jsnPR_COMMENTS}" | jq '.[].body' | grep -oP ':shipit:' )"
if [ -n "${chkApproved}" ] ; then
  echo "YEP! *approve* shipit comment exists "
  return 0
else
  echo "NOPE! approve shipit comment *not* added "
jsn=$(
cat << EOF | jq -s -R '.' | jq '{body: .}'
approve :shipit:
EOF
)
repoCreate "${PR_COMMENTS_URL}" "${JSN_PR_COMMENT}" "${jsn}" \
  && return 0 || return 1
fi
}


function prMergeableStateTasks(){
echo "TASK!  mergeable state preconditions"
echo "INFO! - *PR_MERGED*: [ ${PR_MERGED} ]"
echo "INFO! - *PR_MERGEABLE*: [ ${PR_MERGEABLE} ]"
echo "INFO! - *PR_MERGEABLE_STATE*: [ ${PR_MERGEABLE_STATE} ]"
[ ${PR_MERGED} = 'false' ] || return 1
[ ${PR_MERGEABLE} = 'true' ]  || return 1
#https://github.com/openshift/test-pull-requests/blob/master/test_pull_requests#
case ${PR_MERGEABLE_STATE} in
 'clean'  )
 echo "INFO! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE "
 ;;
 'unstable'  )
  echo "INFO! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE"
  echo "FAILURE! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE "
  return 1
 ;;
 'dirty'  )
  echo "INFO! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE"
  echo "FAILURE! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE "
  return 1
 ;;
 'checking'  )
  echo "INFO! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE"
  echo "FAILURE! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE "
  return 1
 ;; 
  *)
  echo "INFO! - ${PR_MERGEABLE_STATE} MERGEABLE_STATE "
  echo "FAILURE! - unstable MERGEABLE_STATE "
  return 1
  ;;
esac 

[ ${PR_MERGEABLE_STATE} = 'clean' ]  || return 1
echo "OK! met mergeable state preconditions"

REPO_COMMITS_URL=$(
  node -pe "require('${GITHUB_REPO}')['commits_url']" |
  sed -r 's/\{.+//g'
  )
PR_STATUS_URL="${REPO_COMMITS_URL}/${PR_HEAD_SHA}/status"
echo "INFO! - *PR_STATUS_URL*: [ ${PR_STATUS_URL} ]"
echo "INFO! - *PR_STATUSES_URL*: [ ${PR_STATUSES_URL} ]"
echo "INFO! - *PR_COMMITS_URL*: [ ${PR_COMMITS_URL} ]"
#repoFetch "${PR_STATUSES_URL}" "${GITHUB_PR_STATUSES}" || return 1
#repoFetch "${PR_COMMITS_URL}" "${GITHUB_PR_COMMITS}" || return 1
echo "TASK! establish combined status of pull request"
repoFetch "${PR_STATUS_URL}" "${JSN_PR_STATUS}" || return 1
PR_STATUS_STATE=$(
  node -pe "require('${GITHUB_PR_STATUS}')['state']" 
  )
  echo "INFO! - *PR_STATUS_STATE*: [ ${PR_STATUS_STATE} ]"

#TODO! display status reports
if [ "${PR_STATUS_STATE}" = 'success' ] ; then
  echo 'INFO! Lookin good ... going to merge'
  prPushToRemote || return 1
  echo "TASK! Merge branch: *${CURRENT_BRANCH}* into *master*"
jsn=$(cat << EOF
{
"commit_message": "pull request merged #${ISSUE_NUMBER} summary - ${ISSUE_SUMMARY}"
} 
EOF
)
  repoPut "${PR_URL}/merge" "${JSN_MERGE}" "${jsn}" || return 1
  if [ -e ${JSN_MERGE} ] ; then
    MERGED=$(node -pe "require('${GITHUB_MERGE}')['merged']" )
    echo "SUCCESS! - *MERGED* [ ${MERGED} ]"
    repoFetch ${PR_URL} ${JSN_PULL_REQUEST} || return 1
    parsePullRequest  || return 1
    if [ ${PR_MERGED} = 'true' ] ; then
      echo "TASK! checkout master" 
      doTask=$( git checkout ${PR_BASE_REF} )
      echo "DONE! checked out master ${doTask}"
      source "${BIN_DIR}/project.properties"
      echo "INFO! - CURRENT_BRANCH [ ${CURRENT_BRANCH} ]"
      if [ ${CURRENT_BRANCH} = 'master' ] ; then
        echo "TASK! working directory up to date with origin" 
        #The --prune option removes remote-tracking branches that no longer exist on the
        doTask=$( git pull --prune )
        echo "DONE! ${doTask}"
        echo "TASK! delete local branch: ${CURRENT_BRANCH}"
        doTask=$(git branch -D ${PR_HEAD_REF})
        echo "DONE! ${doTask}"
        echo "TASK! delete remote branch ${CURRENT_BRANCH}"
        doTask=$(git push origin --delete ${PR_HEAD_REF})
        echo "DONE! ${doTask}"
        echo "TASK! delete issue and associated pull-request files"
        [ -e ${JSN_ISSUE} ] && {
         etagFile=$(parseIntoETAG ${JSN_ISSUE})
         rm ${JSN_ISSUE}
         rm ${etagFile}
         }
        [ -e ${JSN_PULL_REQUEST} ] && {
         etagFile=$(parseIntoETAG ${JSN_PULL_REQUEST})
         rm ${JSN_PULL_REQUEST}
         rm ${etagFile}
         }
        [ -e ${JSN_PR_STATUSES} ] && {
          etagFile=$(parseIntoETAG ${JSN_PR_STATUSES})
          rm ${JSN_PR_STATUSES}
          rm ${etagFile}
          }
        [ -e ${JSN_PR_COMMITS} ] && {
          etagFile=$(parseIntoETAG ${JSN_PR_COMMITS})
          rm ${JSN_PR_COMMITS}
          rm ${etagFile}
          }
        [ -e ${JSN_PR_STATUS} ] && {
          etagFile=$(parseIntoETAG ${JSN_PR_STATUS})
          rm ${JSN_PR_STATUS}
          rm ${etagFile}
          }
        [ -e ${JSN_PR_COMMENTS} ] && {
          etagFile=$(parseIntoETAG ${JSN_PR_COMMENTS})
          rm ${JSN_PR_COMMENTS}
          rm ${etagFile}
          }
        [ -e ${JSN_PR_COMMENT} ] && {
          etagFile=$(parseIntoETAG ${JSN_PR_COMMENT})
          rm ${JSN_PR_COMMENT}
          rm ${etagFile}
         }
        [ -e ${JSN_MERGE} ] && {
          etagFile=$(parseIntoETAG ${JSN_MERGE})
          rm ${JSN_MERGE}
          rm ${etagFile}
          }
        echo "TASK! make sure repo and repo-lists are up to date"
        touch ${CONFIG_FILE}
        make repo
      else
        echo "FAILURE! - "
        return 1
      fi
    fi
  fi
fi
}


function prPriorMerge(){
#branchCommitOnCompletedTask > /dev/null
#branchSyncIssue  > /dev/null
echo "TASK!  mergeable state preconditions"
##Criteria for merging
## * tests  -  we have run any integration tests and posted
##             'success' status
##    https://developer.github.com/v3/repos/statuses/
## * comments - someone else has reviewed and commented on pull-request
##    https://developer.github.com/v3/issues/comments/
#
cat << EOF
CRITERIA TO SATISFY BEFORE MERGING
----------------------------------

 1.  pull request should be in a mergable and clean state

    MERGEABLE [ ${PR_MERGEABLE} ]
    MERGEABLE_STATE  [ ${PR_MERGEABLE_STATE} ]

 2. a combined 'success' status after we have ran deployment integration *tests*

    COMBINED_STATUS_STATE [ ${PR_COMBINED_STATUS_STATE} ]

 3. have reviewed conversation comments around pull-request
    note pull-requests are issues

    PR_COMMENTS [ ${PR_COMMENTS} ] At least 2 comments

EOF

if [ "${PR_MERGED}" = 'false' ] ; then
  echo "OK! - *PR_MERGED*: [ ${PR_MERGED} ]"
else
  echo "FAIL! - *PR_MERGED*: [ ${PR_MERGED} ]"
  return 1
fi

if [ "${PR_MERGEABLE}" = 'true' ] ; then
  echo "OK! - *PR_MERGEABLE*: [ ${PR_MERGEABLE} ]"
else
  echo "FAIL! - *PR_MERGEABLE*: [ ${PR_MERGEABLE} ]"
  return 1
fi

if [ "${PR_MERGEABLE_STATE}" = 'clean' ] ; then
  echo "OK! - *PR_MERGEABLE_STATE*: [ ${PR_MERGEABLE_STATE} ]"
else
  echo "FAIL! - *PR_MERGEABLE_STATE*: [ ${PR_MERGEABLE_STATE} ]"
  return 1
fi

if [ "${PR_COMMENTS}" -ge 2 ] ; then
  echo "OK! - *PR_COMMENTS*:  [ ${PR_COMMENTS} ] greater than or equal to 2"
else
  echo "FAIL! - *PR_COMMENTS*: [ ${PR_COMMENTS} ]"
  echo "INFO! - *PR_COMMENTS*: should be  greater than or equal to 2"
  return 1
fi

if [ "${PR_COMBINED_STATUS_STATE}" = 'success' ] ; then
  echo "OK! - *PR_COMBINED_STATUS_STATE*: [ ${PR_COMBINED_STATUS_STATE} ]"
else
  echo "FAIL! - *PR_COMBINED_STATUS_STATE*: [ ${PR_COMBINED_STATUS_STATE} ]"
   return 1
fi
return 0
}

function mergedPullRequest(){
if [ "${PR_MERGED}" = 'true' ] ; then
  echo "OK! - *PR_MERGED*: [ ${PR_MERGED} ]"
else
  echo 'FAIL! pull request not merged'
  return 1
fi

[ -z "${PR_BASE_REF}" ] && return 1
[ -z "${PR_HEAD_REF}" ] && return 1


echo "TASK! checkout master"
doTask=$( git checkout ${PR_BASE_REF} )
echo "DONE! checked out master ${doTask}"
source "${BIN_DIR}/project.properties"
echo "INFO! - CURRENT_BRANCH [ ${CURRENT_BRANCH} ]"
if [ ${CURRENT_BRANCH} = 'master' ] ; then
  echo "TASK! working directory up to date with origin"
  #The --prune option removes remote-tracking branches that no longer exist on the
  doTask=$( git pull --prune )
  echo "DONE! ${doTask}"
  echo "TASK! delete local branch: ${CURRENT_BRANCH}"
  doTask=$(git branch -D ${PR_HEAD_REF})
  echo "DONE! ${doTask}"
  echo "TASK! delete remote branch ${CURRENT_BRANCH}"
  doTask=$(git push origin --delete ${PR_HEAD_REF})
  echo "DONE! ${doTask}"
  echo "TASK! delete issue and associated pull-request files"
  [ -e ${JSN_ISSUE} ] && {
   etagFile=$(parseIntoETAG ${JSN_ISSUE})
   rm ${JSN_ISSUE}
   rm ${etagFile}
   }
  [ -e ${JSN_PULL_REQUEST} ] && {
   etagFile=$(parseIntoETAG ${JSN_PULL_REQUEST})
   rm ${JSN_PULL_REQUEST}
   rm ${etagFile}
   }
  [ -e ${JSN_PR_STATUSES} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_STATUSES})
    rm ${JSN_PR_STATUSES}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMITS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMITS})
    rm ${JSN_PR_COMMITS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_STATUS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_STATUS})
    rm ${JSN_PR_STATUS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMENTS} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMENTS})
    rm ${JSN_PR_COMMENTS}
    rm ${etagFile}
    }
  [ -e ${JSN_PR_COMMENT} ] && {
    etagFile=$(parseIntoETAG ${JSN_PR_COMMENT})
    rm ${JSN_PR_COMMENT}
    rm ${etagFile}
   }
  [ -e ${JSN_MERGE} ] && {
    etagFile=$(parseIntoETAG ${JSN_MERGE})
    rm ${JSN_MERGE}
    rm ${etagFile}
    }
fi

}


#  echo 'INFO! Lookin good ... going to merge'
#  echo "CHECK! for commits on *master* not in *${CURRENT_BRANCH}*"
#  return
#  chk=$( git log ..master )
#  if [[ -z ${chk} ]] ; then
#	  echo "YEP! *no* rebase required"
#  else
#	  #return 1
#	  echo "NOPE! there are commits on *master* not in *${CURRENT_BRANCH}*"
#	  echo "TASK!  rebase required"
#	  doTask=$( git rebase -i master ${CURRENT_BRANCH} )
#	  #git rebase -i master enhancement-11-First-working-build
#	  echo "DONE!  ${doTask}"
#  fi
#  echo "TASK!  tidy up merge message "
#  closeIssueLine="This resolves #${PR_NUMBER}"

#  try closing pull request issue with message 

#function  prMergeableStateTasks(){
#parseIssueMD 
## to establish current state of our pull request
##  we do a GET on the PR_URL
##  from this we find the PR_MERGEABLE_STATE
##  which can be either 'clean, unstable' ???   
##  
## we can also get-the-combined-status-for-a-specific-ref
##  https://developer.github.com/v3/repos/statuses
##  there is also a URL for acollection (array) of statuses for a ref
## the 2 URLs use the sha of the branch  .head.sha 
##  we call them PR_STATUSES_URL  and PR_STATUS_URL (combined status )
##  you can create a status state by posting to PR_STATUSES_URL
##  with a state , description and context
## a unique context will add to the STATUSES collection
## ( i.e. a REF can have differing statuses for different contexts
## e.g. a ci test failed , linter failed, not approved etc )
## in other words the statuses array indexes are defined by unique contexts
## a post to PR_STATUSES_URL with the same context e.g. 'default'
## the index will remain same, however array length will increase only if we have
## anothe context  
## With a GET on the PR_STATUS_URL a combined state is returned
##The state is one of:
##    failure if any of the contexts report as error or failure
##    pending if there are no statuses or a context is pending
##    success if the latest status for all contexts is success
##
##  this 
##  not sure about this but this combined state refects back into
## PR_MERGEABLE_STATE got from a GET on the PR_URL
##
##
##  
##  
#[ -e  ${GITHUB_PULL_REQUEST} ] || return 1
#
#  
#jsnPULL_REQUEST="$(<${GITHUB_PULL_REQUEST})"
#echo "ASK! tasks after pull request before merge"
#PR_STATUSES_URL=$(node -pe "require('${GITHUB_PULL_REQUEST}')['statuses_url']")
#echo "INFO! - *PR_STATUSES_URL*: [ ${PR_STATUSES_URL} ]" 
#REPO_COMMITS_URL=$(
#  node -pe "require('${GITHUB_REPO}')['commits_url']" |
#  sed -r 's/\{.+//g'
#  )
#    
#PR_STATUS_URL="${REPO_COMMITS_URL}/${PR_HEAD_SHA}/status"
#echo "INFO! - *PR_STATUS_URL*: [ ${PR_STATUS_URL} ]"
#echo "TASK! establish combined status of pull request"
#repoFetch "${PR_STATUS_URL}" "${GITHUB_PR_STATUS}" || return 1
#PR_STATUS_STATE=$(
#  node -pe "require('${GITHUB_PR_STATUS}')['state']" 
#  )
#  echo "INFO! - *PR_STATUS_STATE*: [ ${PR_STATUS_STATE} ]"
#  
#PR_STATUS_DESCRIPTION=$(
#  node -pe "require('${GITHUB_PR_STATUS}')['statuses'][0]['description']" 
#  )
#PR_STATUS_CONTEXT=$(
#  node -pe "require('${GITHUB_PR_STATUS}')['statuses'][0]['context']" 
#  )
#echo "INFO! - *PR_STATUS_DESCRIPTION*: [ ${PR_STATUS_DESCRIPTION} ]"
#echo "INFO! - *PR_STATUS_CONTEXT*: [ ${PR_STATUS_CONTEXT} ]"
##if [[ ! "${PR_STATUS_STATE}" = 'success' ]] ; then
##    if utilityAskYesNO "${question}" ; then
##        jsn=$(
##        echo "{\"state\":\"success\",\
##        \"description\":\"approved and integration tests completed\" ,\
##        \"context\": \"default\" }" | jq -c -r '.'
##        )
##    
##        if ! repoPost "${PR_STATUSES_URL}" "${GITHUB_PR_STATUS}" "${jsn}"
##            then
##            return 1
##        fi
##    fi
##fi
#
#if [[ "${PR_STATUS_STATE}" = 'success' ]] ; then
#  echo 'INFO! Lookin good ... going to merge'
#  echo "CHECK! for commits on *master* not in *${CURRENT_BRANCH}*"
#  return
#  chk=$( git log ..master )
#  if [[ -z ${chk} ]] ; then
#	  echo "YEP! *no* rebase required"
#  else
#	  #return 1
#	  echo "NOPE! there are commits on *master* not in *${CURRENT_BRANCH}*"
#	  echo "TASK!  rebase required"
#	  doTask=$( git rebase -i master ${CURRENT_BRANCH} )
#	  #git rebase -i master enhancement-11-First-working-build
#	  echo "DONE!  ${doTask}"
#  fi
#  echo "TASK!  tidy up merge message "
#  closeIssueLine="This resolves #${PR_NUMBER}"
## step 1 not sure about last rebase???
#
## step 2 tidy up merge message
##echo 'Ship worked on feature via an explicit merge with master branch"
##echo 'Feature will be official on  master branch "
##echo 'If we have used rebase to keep feature branch up to date,"
##echo 'the actual merge commit will not include any changes"
## The Git history contains only one clean commit per feature / bug fix
## todo merge message
##  try closing pull request issue with message 
#  echo "TASK! Merge branch: *${CURRENT_BRANCH}* into *master*"
#  PULLS_URL=$(node -pe "require('${GITHUB_PULL_REQUEST}')['url']")  
#  echo "INFO! - *PULLS_URL* [ ${PULLS_URL} ]"
#  
#  echo 'INFO! Lookin good ... going to merge'
#  jsn=$(cat << EOF
#  {
#  "commit_message": "pull request merged #${ISSUE_NUMBER} summary - ${ISSUE_SUMMARY}"
#  } 
#  EOF
#  )
#  
#  repoPut "${PULLS_URL}/merge" "${GITHUB_MERGE}" "${jsn}"
#  
#  if [ -e ${GITHUB_MERGE} ] ; then
#	MERGED=$(node -pe "require('${GITHUB_MERGE}')['merged']" )
#	echo "INFO! - *MERGED* [ ${MERGED} ]"
#  fi
#  
##  git checkout master
##  git merge \
##	  --no-ff \
##	  --log \
##	  --progress \
##	  --verbose \
##	  ${CURRENT_BRANCH}
##  git push origin master
##  echo "TASK! delete local branch: ${CURRENT_BRANCH}"
##  doTask=$(git branch -D ${CURRENT_BRANCH})
##  echo "DONE! ${doTask}"
##  echo "TASK! delete remote branch ${CURRENT_BRANCH}"
##  doTask=$(git push origin --delete ${CURRENT_BRANCH})
##  echo "DONE! ${doTask}"
#        
##now create release with release artifact
#    #if utilityAskYesNO "${question}" ; then
#    # question='do you want to tag and release on github ' 
#    # if utilityAskYesNO "${question}" ; then
#    #    if ! releaseCreateRelease ; then
#    #      return 1
#    #    fi
#    # else
#    #     return 0 
#    # fi
#    #    
#    #fi
#fi
#
#
#    
#    
#    # todo check statuses of empty explitly upload pending state
#    
#    
##    echo "CHECK! if pull request status set on github  "
##    jsnPR_STATUS=$( cat ${GITHUB_PR_STATUS} )
##    chkEmpty=$( echo  "${jsnPR_STATUS}"  | jq ' . |  length' )
##    if [[ $chkEmpty -ne 0 ]] ; then
##         echo "YEP! status set and available'    
##    else
##        echo "NOPE! status not yet set "
##        echo "TASK! set status of pull_request to pending "
##    
##       jsn=$(
##        echo "{\"state\":\"pending\",\
##        \"description\":\"waiting for review and integration tests\" ,\
##        \"context\": \"default\" }" | jq -c -r '."
##        )
##        echo "INFO! json payload"
###The state of the status. Can be one of pending, success, error, or failure
##        echoLine
##        echo "$jsn" | jq '.'
##        echoLine
##        doRequest=$(
##        curl \
##        -H "Accept: application/json" \
##        -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
##        -o ${GITHUB_PR_STATUS} \
##        -w "%{http_code}" \
##        -d "${jsn}" \
##        ${PR_STATUSES_URL}
##        )
##        if [[ ${doRequest} = 201 ]] ; then
##            echo "OK!  ${doRequest} created status '
##        else
##            echo "FAILURE! ${doRequest}'
##            exit
##        fi    
##    fi
#
## step 2
##

#
#}




