#!/bin/bash +x
############################

function rsSetMilestonesForReleaseStrategy(){
  for item in "${RELEASE_MILESTONES[@]}";
  do
    local title="strategy-${item}"
    local description="${RELEASE_STRATEGY[$item]}"
    echo "$title : [ $description ]"
    gh create-milestone "$title" "$description"
  done
  gh get-milestones
}


#function setIssueLabels(){
#if [ -z ${ISSUE_LABELS_ETAG} ] ; then
#    # get labels from github using api call output to temp
#    curl -i ${API_ISSUE_LABELS} -o ${TEMP_FILE}
#fi
#
#if [ -z ${ISSUE_LABELS_ETAG} ] ; then
#    local issueLabelEtag=$( cat ${TEMP_FILE} | grep -oP 'ETag:\s+\"\K([\w]+)' )
#    if [ ! -z ${issueLabelEtag} ] ; then
#    # if we find etag add to PROJECT_PROPERTIES_FILE so we can make
#    # conditional request later on
#    createIssueLabelsEtag ${issueLabelEtag}
#    fi
#fi
#
#if [ -z ${ISSUE_LABELS[1]} ] ; then
#    local issueLabel=$( cat ${TEMP_FILE} | json -H json -a name )
#    createIssueLabels
#fi
#
#}
