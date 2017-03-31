#!/bin/bash +x


function inputSelectIssueForBranch(){
  options=()
  for i in "${!ISSUES_FOR_BRANCHES[@]}"
      do
         options+=(${ISSUES_FOR_BRANCHES[i]})
      done
  echo "INPUT! Select issue for branch"
  utilitySelectOption 'BRANCH_SELECTED' || return 1
  echo "INFO! - *BRANCH_SELECTED*: [ ${BRANCH_SELECTED} ]"
}


function utilityAskYesNO(){  
local question="${1}"
[ -z "$( echo $TERM )" ] && return 1
while true; do
    read -s -n 1 -p \
    "${CLR_INPUT} ➯ ${CLR_RESET} ${question}\
    (Y/N)? ${CLR_INPUT}↳${CLR_RESET} " \
    answer
    case $answer in
        [Yy]*|"")
            echo '  YEP!'
            return 0
            break;;
        [Nn]* )
            echo '  NOPE!'
            return 1
            break;;
        * )
		  echo "INFO! Please answer yes or no."
		;;
    esac
done
}

function utilitySelectNumber(){
local question="${1}"
local jsnARR=$(<${2})
echo "${jsnARR}" | R   'project [\number \title \description]'  -o table
local jsnArrLength=$(echo "${jsnARR}" | R   '.length')
while true; do
    read -s -n 1 -p \
    "${CLR_INPUT} ➯ ${CLR_RESET} ${question}\
    (Y/N)? ${CLR_INPUT}↳${CLR_RESET} " \
    answer
    echo "${answer}"
    if [[ ${answer} -lt 1  || ${answer} -gt ${jsnArrLength} ]] ; then
        echo "INFO! Invalid option. Must be between 1 and ${jsnArrLength}"
        continue
    fi
    break
done
gh picked-milestone ${answer}
}

function inputPrompt(){
# CLR_INPUT=$'\e[0;33m'
# CLR_RESET=$'\e[m'
local rtrn="${1}"
local ask="${2}"
local string=
read -p "${ask}  ${CLR_INPUT} ${rtrn} ${CLR_RESET} ➥ " string
#echo "INFO!  *ISSUE_SUMMARY*: [ ${string} ]"
if [ -n "${string}" ] ; then
  eval ${rtrn}="\"${string}\""
  return 0
else
  return 1
fi

}


function utilitySelectOption(){
local rtrn="${1}"
local SELECTED=
local prompt="${CLR_INPUT} ➯ ${CLR_RESET}\
select option between ( ${CLR_INPUT}1-${#options[@]}${CLR_RESET} ) "
#OK ${clr}($(( ${#options[@]} )))${reset} when done "
PS3="$prompt ${CLR_INPUT}↳${CLR_RESET} "
select opt in "${options[@]}" ; do
    if [[ "${REPLY}" = 'y' || "${REPLY}" = 'Y' ]] ; then
        if [ -z "${SELECTED}" ]; then
            echo "INFO! Invalid option. Nothing selected"
            continue
        else
           break
        fi  
    fi

    if [[ ${REPLY} -lt 1  || ${REPLY} -gt $(( ${#options[@]} )) ]] ; then
        echo "INFO! Invalid option. Must be between 1 and $(( ${#options[@]} ))"
        continue 
    fi

    SELECTED="${opt}"
    echo "ACTION! selected *${SELECTED}*"
    if utilityAskYesNO 'OK with choice' ; then
        break
    else
        continue
    fi
done
eval ${rtrn}="\"${SELECTED}\""
return 0
}



function foldr(){
[ -z "$( echo $TERM )" ] && return 0				 
fold -w $( tput cols ) -s
}

function echoLine(){
[ -z "$( echo $TERM )" ] && return 0
local line=$1
if [[ -z $line ]] ; then
 line='-'
fi
printf '%*s' "$(tput cols)" '' | tr ' ' ${line}
}
