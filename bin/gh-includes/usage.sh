#!/bin/bash +x

function ghUsage(){
cat << EOF
usage: $0 OPTION REQUEST ARGUMENTS

OPTIONS can be:
  -h	Show this message
  -l	list available requests

REQUEST the request to make

ARGUMENTS any arguments required to run the request

gh get-milestones
npm run gh -- get-milestones

npm run gh -- get-issue {number}

EOF
}

function ghListAvailableRequests(){
local file=$(<${BIN_DIR}/gh)
local start=$(
  echo "${file}" |
  sed -n '/#LIST-START#/='
  )
  
local pattern="${start},/#LIST-END#/p"

sed -n ${pattern}  ${BIN_DIR}/gh |
  sed '1d;$d' |
  grep -zoP '(?s)^\s\s[\w-]+\)$.^\s\sparams=\([a-z ]+\).' |
  sed -r 's/params=\( \)/... no params/g' |
  sed -r 's/params=\(/\tparams: /g' |
  sed -r 's/\)$//g'
}
