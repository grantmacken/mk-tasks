#!/bin/bash
function tmx_watch() {
echo  'tmx_watch'
hasWatch=$(
  tmux list-windows -t $SESSION -F '#W' | grep 'watch'
  )

if [ -z "${hasWatch}" ] ; then
  tmux new-window -n watch
  tmux split-window -t watch
  tmux select-layout -t watch tiled
  tmux split-window -t watch
  tmux select-layout -t watch tiled
  tmux split-window -t watch
  tmux select-layout -t watch tiled
  tmux split-window -t watch
  tmux select-layout -t watch tiled
  tmux send-keys -t watch.1 "make livereload-start"  C-m
  tmux send-keys -t watch.2 "make watch-www"  C-m
  tmux send-keys -t watch.3 "make watch-templates"  C-m
  tmux send-keys -t watch.4 "make watch-modules"  C-m
fi
}

function mxInit(){
  source <( sed 's/=/="/g' config | sed -r 's/$/"/g' )
  source ../common.properties
  source ../project.properties
  clear
}

function mxGitHead(){
  git rev-parse --short HEAD
}

function mxNginxAccessLog(){
  tailf -n 1 /var/log/nginx/file.log |
  awk '{ printf("%-15s\t%s\t%s\t%s\n", $1,  $6, $9, $7)}'
}

function mxNginxErrorLog(){
  tailf /var/log/nginx/error.log |
  grep -oP '"(.+)"\sdoes not match\s"(\S+)"'
}

function mxNginxErrorLogMatches(){
  tailf /var/log/nginx/error.log |
  grep -oP '"(.+)"\smatches\s"(\S+)"'
}

#awk '$20 ~ /GET/{gsub(/"/, "", $24); sub(/[^.]*\./, "", $24); a[$24]++}; END{for (k in a)print k, a[k]}'  /var/log/nginx/error.log

function mxExistUp(){
  curl -I 'http://localhost:8080/' |
  grep -oP '(\KJetty.+$)' 2>/dev/null
}

function mxExistClient(){
  cd $EXIST_HOME
  java -jar start.jar client -s -P $GITHUB_ACCESS_TOKEN -u $GIT_REPO_OWNER_LOGIN
}


function mxExistDBLog(){
  tailf "${XMLDB_LOG}" | awk -v m="\x01" -v N="8" '{$N=m$N; print substr($0,index($0,m)+1)}'
  #awk '{ printf("%-15s\t%s\t%s\t%s\n", $1,  $4, $5 , $8)}'
}

function mxAppDataLog(){
  tailf "${APP_LOG}" | awk -v m="\x01" -v N="7" '{$N=m$N; print substr($0,index($0,m)+1)}'
}

#(\\d{4}-\\d{2}-\\d{2}) (\\d{2}:\\d{2}:\\d{2},\\d{3}) \\[(.*)\\] ([^ ]*) ([^ ]*) - (.*)$
function mxGetRepo(){
while true
do
  gh get-repo
  gh parse-repo
  sleep 1h
done
}

function mxIssueReadme(){
cat <<EOF

1. each feature *branch* is based on an *issue* raised in github. An issue that
can developed into a branch is identified by its label (feature or bug ) and
assocated with a simple *milestone* release strategy

2. each issue has a public *task list* ( the feature branch being worked on)
    * github issue url - what I am working on
    * github issues url- what everbody is working on

3. a watched issue task list ( ISSUES.md )
    * on completion of task (task ticked) when saved
      * the task generates the git commit message
      * local ISSUES.md is synced to github issue so others can see progress made
    * all tasks ticked should mean issue resolved.

4. pull request: when issue resolved create a pull request. The pull request
uses the github issue number, so the task list gets pulled into the pull request

5. satisfy merge criteria prior to merge
    1. reviewed: a human has looked at this and added an approve comment
     (pr-comments url)
    2. status: a machine has looked at this and passed any integration *tests*
     (pr-status ) Tests are run in travis
    3.  pull - commit - push fix any bugs based on comments and tests

6. use github api to create a merge into master
    1. merge message based on ISSUE.md
    2. checkout master - pull --rebase
    3. delete associated local branch and remote tracked branch

7.  build the xar file from sources
  ( app version based on incremented git tag version from last release)

8. use github api to create a *release* and *release asset*.
    1. create release then store response (release.json) - This will also tag
    the release on the remote so after we nedd to pull sync to localy sync
    2. from release.json extract the upload_url 3.
    upload xar as release asset then store response (uploaded.json) 4. from
    release.json uploaded.json extract download_url

9. install and deploy to exist-db

EOF
}


function mxHint(){
cat <<EOF
  systemctl start exist
  systemctl stop exist
EOF
}
