
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
ellse
  return 1
fi
}

function  eXistBinPUT(){
local url=$1
local file=$2
local mimeType=$3
local message=
echo "TASK! eout file and store xml response"
local fileName=$( echo "${file}" | sed 's/.*\///')
local ext=
if [ -e  ${TEMP_XML} ] ; then
 rm ${TEMP_XML}
fi
return 1
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

function  existPUT(){
local url=$1
local file=$2
local message=
echo "TASK! put file and store xml response"
local fileName=$( echo "${file}" | sed 's/.*\///')
local ext=
if [ -e  ${TEMP_XML} ] ; then
 rm "${TEMP_XML}"
fi
return 1
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
$verbose && echo 'TASK! POST QUERY'
$verbose && echo "INFO! TEMP_OUT: ${TEMP_XML}"
local max=9999
# echo ${query}
# import module namespace cm="http://markup.nz#cm" at "modules/lib/commonMark.xqm";
local POST=$(
cat << EOF
<query xmlns="http://exist.sourceforge.net/NS/exist"
	start="1"
	max="${max}">
<text><![CDATA[
xquery version "3.1";
import module namespace md="http://exist-db.org/xquery/markdown";
import module namespace inspect = "http://exist-db.org/xquery/inspection";
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
${import}
${query}
]]></text>
</query>
EOF
)
 # echo "$POST"
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
[ -n "${VERBOSE}" ] && \
echo "DONE! status: [ ${doRequest} ]"
# echo $(<${TEMP_XML})
if [[ ${dorequest} = 200  || ${dorequest} = 304 || ${dorequest} = 201  ]]
then
  if [ -e ${temp_xml} ] ;then
    return 0
  else
    return 1
  fi
else
  return 1
fi
}
