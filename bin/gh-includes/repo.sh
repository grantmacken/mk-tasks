#!/bin/bash +x
function repoRemoveFile(){
local file=$1
local fileName="$( echo "${file}" | sed 's%.*/%%')"
local baseName="$( echo "${fileName}" | cut -d. -f1 )"
#local basePath="$( echo "${file}" | sed 's%fileName%%')"
local headerDump="${GITHUB_DIR}/headers/${baseName}.txt"
local eTagFile="${GITHUB_DIR}/etags/${baseName}.etag"
[ -e ${file} ] && rm ${file} 
[ -e ${eTagFile} ] && rm ${eTagFile} 
[ -e ${headerDump} ] && rm ${headerDump} 
}

function repoShortUrl(){ 
doRequest=$(
curl -s \
  -i \
  -F "url=${LONG_URL}" \
  http://git.io
)
SHORT_URL=$( echo "${doRequest}" | grep -oP 'Location: \K(.+)' )
}

function repoLists(){
  REPO_LISTS=(milestones labels tags issues branches pulls releases )
  for item in "${REPO_LISTS[@]}";
  do
  gh get-$item
  done
}

function repoFetch(){                             
local url=$1
local file=$2
local fileName="$( echo "${file}" | sed 's%.*/%%')"
local baseName="$( echo "${fileName}" | cut -d. -f1 )"
#local basePath="$( echo "${file}" | sed 's%fileName%%')"
local headerDump="${GITHUB_DIR}/headers/${baseName}.txt"
local eTagFile="${GITHUB_DIR}/etags/${baseName}.etag"
local message=
#repoRemoveFile "${file}"
echo "TASK! from github, fetch and store reponse"
echo "INFO! - *GET URL* : [ ${url} ]"
echo "INFO! - *RESPONSE FILE* : [ ${fileName} ]"
echo "INFO! - *fileName* : [ ${fileName} ]"
echo "INFO! - *baseName* : [ ${baseName} ]"
echo "INFO! - *headerDump* : [ ${headerDump} ]"
echo "INFO! - *eTagFile* : [ ${eTagFile} ]"
[ -n "${fileName}" ] ||  return 1
[ -n "${url}" ] || return 1
[ -n "${file}" ] || return 1

#grep -oP '^ETag: \K["\w]+'

if [ -e ${file} ] ;then
   mv ${file} ${TEMP_DIR}/${fileName}
fi

if [ -e ${eTagFile} ] ;then
  local ETAG=$(<${eTagFile})
  echo "INFO! - *ETAG* : [ ${ETAG} ]"
  doRequest=$(
    curl -s \
    -X GET \
    -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
    -H "If-None-Match: \"${ETAG}\"" \
    -o  ${file} \
    -w %{http_code} \
    --dump-header  ${headerDump} \
    ${url}
    )
  else
     echo "INFO! - *ETAG* : [ no-eTag ]"
    doRequest=$(
    curl -s \
    -X GET \
    -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
    -o  ${file} \
    -w %{http_code} \
    --dump-header  ${headerDump} \
    ${url}
    )  
fi
  
case "${doRequest}" in
  200)
    echo "OK! response ${doRequest}. OK"
    echo "INFO! response *stored* as: [ ${fileName} ]"
    echo "$(<${headerDump})" | grep -oP '^ETag: "\K(\w)+' > ${eTagFile}
    rm ${TEMP_DIR}/${fileName}
    return 0
  ;;
  304)
    echo "OK! response ${doRequest}. OK"
    echo "INFO! ${fileName} is already up to date so will not be modified]"
    mv ${TEMP_DIR}/${fileName} ${file}
    return 0
  ;;
  *)
    echo "FAILURE! response ${doRequest}."
    if [ -e "${file}" ] ; then
      message=$(  cat "${file}" | jq '.message' )
    fi
    echo "FAILURE! - response [${doRequest}] ${message}"
    return 1
esac
}

function repoCreate(){                             
local url="$1"
local file="$2"
local jsn="$3"
local message=
# repoRemoveFile "${file}"
local fileName=$( echo "${file}" | sed 's/.*\///')
echo "TASK! post json to url and store json response"
echo "INFO! - *POST URL* : [ ${url} ]"
echo "INFO! - *RESPONSE FILE* : [ ${file} ]"
echo "INFO! json payload to send"
echo "${jsn}"
[ -n "${fileName}" ] ||  return 1
[ -n "${url}" ] || return 1
[ -n "${file}" ] || return 1
[ -n "${jsn}" ] || return 1
doRequest=$(
curl -s \
-H "Accept: application/json" \
-H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
-o "${file}" \
-w "%{http_code}" \
-d "${jsn}" \
${url}
)

if [ -e "${file}" ] ; then
  if [[ ${doRequest} = 201 ]] ; then
	echo "OK! response ${doRequest}, created"
	echo "SUCCESS! stored json reply as:  ${file}"
	return 0
  else
	echo "FAILURE! response ${doRequest}. post failure"
	if [ -e "${file}" ] ; then
	  # try to get failure message
	  message=$(  cat "${file}" | jq '.message' )
	  if [ -n "${message}" ] ; then
		echo "FAILURE! - response [${doRequest}] ${message}"
	  else
		# dump it all
		cat "${file}" | jq ''
	  fi
	fi
	#clean up
	# repoRemoveFile "${file}"
	return 1
  fi
else
  echo "FAILURE! - response file not created"
  return 1
fi
}

function repoPatch(){
local url="$1"
local file="$2"
local jsn="$3"
local fileName=$( echo "${file}" | sed 's/.*\///')
local message=
# repoRemoveFile "${file}"
echo "TASK! post json to url and store json response"
echo "INFO! - *POST URL* : [ ${url} ]"
echo "INFO! - *RESPONSE FILE* : [ ${file} ]"
echo "INFO! json payload to send"
echo "$jsn"
[ -n "${fileName}" ] ||  return 1
[ -n "${url}" ] || return 1
[ -n "${file}" ] || return 1
[ -n "${jsn}" ] || return 1
doRequest=$(
curl -s \
  -X PATCH \
  -H "Accept: application/json" \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -o "${file}" \
  -w "%{http_code}" \
  -d "${jsn}" \
  ${url}
)

if [[ ${doRequest} = 200 ]] ; then
    echo "OK! response ${doRequest}, patched"
    echo "INFO! stored json reply as:  ${file}"
     return 0
else
    echo "FAILURE! response ${doRequest}. post failure"
	if [ -e "${file}" ] ; then
	  # try to get failure message
      message=$(  cat "${file}" | jq '.message' )
	  if [ -n "${message}" ] ; then
		echo "FAILURE! - response [${doRequest}] ${message}"
	  else
		# dump it all
		cat "${file}" | jq ''
	  fi
    fi
	#clean up
	# repoRemoveFile "${file}"
    return 1
fi 
}
  
function repoPut(){
local url="$1"
local file="$2"
local jsn="$3"
local fileName=$( echo "${file}" | sed 's/.*\///')
local message=
# repoRemoveFile "${file}"
echo "TASK! put json to url and store json response"
echo "INFO! - *PUT URL* : [ ${url} ]"
echo "INFO! - *RESPONSE FILE* : [ ${file} ]"
echo "INFO! json payload to send"
echo "$jsn" | jq '.'
[ -n "${fileName}" ] ||  return 1
[ -n "${url}" ] || return 1
[ -n "${file}" ] || return 1
[ -n "${jsn}" ] || return 1
doRequest=$(
curl -s \
  -X PUT \
  -H "Accept: application/json" \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -o "${file}" \
  -w "%{http_code}" \
  -d "${jsn}" \
  ${url}
)

if [[ ${doRequest} = 405 ]] ; then
    echo "OK! response ${doRequest}, method not allowed"
    echo "INFO! stored json reply as:  ${file}"
    if [ -e "${file}" ] ; then
	  # try to get failure message
      message=$(  cat "${file}" | jq '.message' )
	  if [ -n "${message}" ] ; then
		echo "FAILURE! - response [${doRequest}] ${message}"
	  else
		# dump it all
		cat "${file}" | jq ''
	  fi
    fi
fi

if [[ ${doRequest} = 200 ]] ; then
    echo "OK! response ${doRequest}, patched"
    echo "INFO! stored json reply as:  ${file}"
     return 0
else
    echo "FAILURE! response ${doRequest}. post failure"
	if [ -e "${file}" ] ; then
	  # try to get failure message
      message=$(  cat "${file}" | jq '.message' )
	  if [ -n "${message}" ] ; then
		echo "FAILURE! - response [${doRequest}] ${message}"
	  else
		# dump it all
		cat "${file}" | jq ''
	  fi
    fi
	#clean up
	# repoRemoveFile "${file}"
    return 1
fi 
}

function repoUpload(){
local request_url="$1"
local response_file="$2"
local up_file="$3"
local content_type="$4"
local message=
# repoRemoveFile "${response_file}"
echo "#RELEASE ARTIFACT#"
echo "TASK! upload to github lastest xar as release artifact "
echo "INFO! - *RELEASE_UPLOAD_URL*: [ ${request_url} ]"
echo "INFO! - *BUILD_LOCATION*: [ ${up_file} ]"
echo "INFO! - *RESPONSE_FILE*: [ ${response_file} ]"
#Uploads are handled by a single request to a companion “uploads.github.com” service
[ -n "${request_url}" ] ||  return 1
[ -n "${response_file}" ] || return 1
[ -n "${up_file}" ] || return 1
[ -n "${content_type}" ] || return 1
doRequest=$(
curl \
  -X POST \
  -H "Accept: application/json" \
  -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
  -H "Content-Type:${content_type}" \
  -o ${response_file} \
  -w "%{http_code}" \
  --data-binary "@${up_file}" \
  ${request_url}
)

if [[ ${doRequest} = 201 ]] ; then
    echo "OK! response ${doRequest}, created"
    echo "INFO! stored json reply as:  ${response_file}"
	#echo "$(<${response_file})" | jq -r '.'
	return 0
else
    echo "FAILURE! response ${doRequest}. post failure"
	#echo "$(<${response_file})" | jq -r '.'
	return 1
fi
#echo "$(<${response_file})" | jq -r '.browser_download_url'
}

function repoDelete(){                             
local url=$1
echo "TASK! delete request "
echo "INFO! - *DELETE URL* : [ ${url} ]"
doRequest=$(
curl \
-X DELETE \
-H "Accept: application/json" \
-H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
-w "%{http_code}" \
${url}
)
   
if [[ ${doRequest} = 204 ]] ; then
    echo "OK! response ${doRequest}. OK"
	echo "SUCCESS! - response [${doRequest}] ${message}"
    return 0
else
    echo "FAILURE! response ${doRequest}."
    if [ -e "${file}" ] ; then
      message=$(  cat "${file}" | jq '.message' )
    fi
   echo "FAILURE! - response [${doRequest}] ${message}"
   return 1
fi
}
