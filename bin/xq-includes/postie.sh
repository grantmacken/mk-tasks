#!/bin/bash +x
function repoRemoveFile(){
local file=$1
if [ -e "${1}" ] ; then
    echo "TASK!  remove ${file}"
    doTask=$( rm -v "${file}")
    echo "DONE! -  ${doTask}"
fi
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
    return 0
  ;;
  304)
    echo "OK! response ${doRequest}. OK"
    echo "INFO! ${fileName} is already up to date so will not be modified]"
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



function existGET(){
if [ -e  ${TEMP_XML} ] ; then
 rm ${TEMP_XML}
fi

url="http://${HOST}:8080/exist/rest${remotePath}"
echo "TASK! put xml to remote"
echo "INFO! - *GET URL* : [ ${url} ]"
#echo "INFO! - *RESPONSE FILE* : [ ${file} ]"

local doRequest=$(
curl -s \
  -X GET \
  -H "Content-Type: text/xml" \
  -u "${KNOWN_USER}:${KNOWN_PASS}" \
  -o ${TEMP_XML} \
  -w "%{http_code}" \
  ${url}
)
echo "DONE! status: [ ${doRequest} ]"
if [[ ${doRequest} = 200  || ${doRequest} = 304   ]]
then
  if [ -e ${TEMP_XML} ] ;then
	return 0
  else
	return 1
  fi
else
  return 1
fi
}


function  existPUT(){
if [ -e  ${TEMP_XML} ] ; then
 rm ${TEMP_XML}
fi
local doRequest=$(
curl -s \
  -X PUT \
  -H "Content-Type: text/xml" \
  -u "${KNOWN_USER}:${KNOWN_PASS}" \
  -o ${TEMP_XML} \
  -w "%{http_code}" \
  --data-binary @${localFile} \
  http://${HOST}:8080/exist/rest${remotePath}
)
echo "DONE! status: [ ${doRequest} ]"
if [[ ${doRequest} = 200  || ${doRequest} = 304 || ${doRequest} = 201  ]]
then
  if [ -e ${TEMP_XML} ] ;then
	return 0
  else
	return 1
  fi
else
  return 1
fi
}


function existPost(){
local POST=$(   
cat << EOF
<query xmlns="http://exist.sourceforge.net/NS/exist" start="1" max="${max}">
<text><![CDATA[    
${query}
]]></text>
</query>
EOF
)
#echo "$POST"
if [ -e  ${TEMP_XML} ] ; then
 rm ${TEMP_XML}
fi
local doRequest=$(
curl -s \
  -H "Content-Type: text/xml" \
  -u "${KNOWN_USER}:${KNOWN_PASS}" \
  -o ${TEMP_XML} \
  -w "%{http_code}" \
  -d "${POST}" \
  http://${HOST}:8080/exist/rest/db
)
echo "DONE! status: [ ${doRequest} ]"
if [[ ${doRequest} = 200  || ${doRequest} = 304 || ${doRequest} = 201  ]]
then
  if [ -e ${TEMP_XML} ] ;then
	return 0
  else
	return 1
  fi
else
  return 1
fi
}
