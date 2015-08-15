#!/bin/bash +x
function xqUsage(){
cat << EOF
usage: $0 OPTION QUERY ARGUMENTS

OPTIONS can be:
  -h	Show this message
  -r	Query *remote host*, instead of default localhost
  -l	list available queries

QUERY the query to run against the eXist database

ARGUMENTS any arguments required to run the query
 
Notes:
  a query may require no argument e.g. uuid 
  requires no argument

EOF
}

function xqListAvailableQueries(){
local file=$(<${BIN_DIR}/xq)
local start=$(
  echo "${file}" |
  sed -n '/#LIST-START#/='
  )
  
local pattern="${start},/#LIST-END#/p"

sed -n ${pattern}  ${BIN_DIR}/xq |
  sed '1d;$d' |
  grep -zoP '(?s)^\s\s[\w-]+\)$.^\s\sparams=\([a-z ]+\).' |
  sed -r 's/params=\( \)/... no params/g' |
  sed -r 's/params=\(/\tparams: /g' |
  sed -r 's/\)$//g'
}

function ghUsage(){
cat << EOF
usage: $0 OPTION REQUEST ARGUMENTS

OPTIONS can be:
  -h	Show this message
  -l	list available requests

REQUEST the request to make

ARGUMENTS any arguments required to run the request

bin/gh get-milestones
npm run gh -- get-milestones
npm run gh -- get-issue {number}

EOF
}
