#!/bin/bash +x
############################

###############################################################################
# branchSyncIssue
#
# when ISSUE.md is saved
# send patch to github
#

function branchSyncIssue(){
  parseBranchName  > /dev/null
  parseIssueMD  > /dev/null 
  parseFetchedIssue > /dev/null
  if ! branchIssueInSynChecks ; then
    gh patch-issue && {
    notify-send "Upload Issue Patch to GITHUB" -t 200
    } ||  return 1
  fi
}

function branchIssueInSynChecks(){
echo "CHECK! is fetched issue title same as current issue title"
if [[ "${FETCHED_ISSUE_TITLE}" = "${ISSUE_TITLE}" ]] ; then
  echo "YEP! fetched issue title same as current issue title"
  # check 2
  local md5FetchedIssueBody=$(
  echo "$FETCHED_ISSUE_BODY" | \
  sed -r 's/[[:space:]]*$//' |  \
  sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' | \
  md5sum
  )
  local md5MDIssueBody=$(
  echo "$ISSUE_BODY" | \
  sed -r 's/[[:space:]]*$//' |  \
  sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba' | \
  md5sum
  )
  # echo "${md5FetchedIssueBody}"
  # echo "${md5MDIssueBody}"
  echo "CHECK! is fetched issue body same as current issue body"
  if [[ "${md5FetchedIssueBody}" = "${md5MDIssueBody}" ]] ; then
     echo "YEP! fetched issue body same as current issue body"
     return 0
  else
    echo "NOPE! fetched issue body *not* the same as current issue body"
    return 1
 fi
else
  echo "NOPE! fetched issue title *not* the same as current issue title"
  return 1
fi
}

function branchCommitOnCompletedTask(){
[ -e ${JSN_ISSUE} ]  || {
  echo "FAILURE! no file ${JSN_REPO}"
  return 1
  }
[ -z "$(git status -s)" ] && {
   echo "nothing thing to commit, working directory clean"
  return 1  
}
# commit based on completed tasks

parseIntoArrayCommitsHash 'COMMITS_HASH'
parseIntoArrayCommitsSubject 'COMMITS_SUBJECT'
parseIntoArrayFinishedTasks 'ISSUE_FINISHED_TASKS'
echo  "INFO! -  completed finished tasks [ ${#ISSUE_FINISHED_TASKS[@]} ] "
echo  "INFO! -  commits since last merge [ ${#COMMITS_SUBJECT[@]} ]"

[ ${#ISSUE_FINISHED_TASKS[@]} -eq 0 ] && return 0
count=0
for i in ${!ISSUE_FINISHED_TASKS[@]}; do
  str=$( echo "${ISSUE_FINISHED_TASKS[${i}]}"  | tr -d "'" )
  (( count++ ))
  echo "INFO! - [${count}] ${str} "
  match=$(
    grep -oP "${str}" $TEMP_COMMITS_SUBJECTS
    )
  if  [ -n "${match}" ] ; then
    echo "OK! [${count}]  ${str}"
  else
    echo "TASK! commit task [${count}]  with message [ ${str} ]"
    doTask=$(git commit -am "'${str}'")
    echo "DONE! commited $(git log --oneline -1 )"
    notify-send "commited $(git log --oneline -1 )" -t 3000
    break
  fi
done
}

function branchCreateTestPlan(){
echo "TASK! create test file for issue"
cat << EOF | tee t/${ISSUE_NUMBER}.t
#!/usr/bin/env bash
TEST_MORE_PATH='bin/ext/test-more-bash'
BASHLIB="\$(
  find \$TEST_MORE_PATH -type d |
  grep -E '/(bin|lib)\$' |
  xargs -n1 printf "%s:"
  )"
PATH="\$BASHLIB\$PATH"
source bash+ :std
use Test::More

plan tests 1

note "issue: ${ISSUE_NUMBER} - ${ISSUE_TITLE} "

pass

note "FIN"

EOF

git add t/${ISSUE_NUMBER}.t

echo "DONE! created test file for issue"
}

