#!/bin/bash +x

############################################################
#  Subscript: utility funcs
#  Author : Grant MacKenzie
#  
# screen funcs
#   afterReadClear
#   foldr
#   echoLine
#   setPassword  hidden pass word
#
# ☂ ► ✓ ✗ ☹ ⚑ ⚐
# ☺ ☻ ☹
# ✍ ✎
# ★ ☆ ☕ ✁
# ✿ ❀ ✣ ✦ ✪ ✰ ☼
# ➯ ➥ ➤ ↺ ↳ ⏎ ↵ ↵ ↵ ↵
# ⚠ ⌛ ⚡ ℹ
# ❶ ❷ ❸
############################################################

#USER INPUT
#   utilityAskYesNO
#   utilitySelectOption
#   setPassword
#
#PROPERTY FILES
# used as source
#  source 'file_name.property'
#  setProperty
#   

utilityFunctionExists() {
    declare -f -F $1 > /dev/null
    return $?
}


function utilityAskYesNO(){
local question="${1}"
local clr=$'\e[0;33m'
local reset=$'\e[m'  
while true; do
    read -p \
    "${clr} ➯ ${reset} ${question}\
    (Y/N)? ${clr}↳${reset} " \
    answer
    case $answer in
        [Yy]* )
            echoMD 'YEP!'
            return 0
            break;;
        [Nn]* )
            echoMD 'NOPE!'
            return 1
            break;;
        * ) echoMD 'INFO! Please answer yes or no.';;
    esac
done
}

function utilitySelectOption(){
local rtrn="${1}"
local SELECTED=
local clr=$'\e[0;33m'
local reset=$'\e[m'  
local prompt="${clr} ➯ ${reset}\
select option between ${clr}1-$(( ${#options[@]}- 1 ))${reset}"
#OK ${clr}($(( ${#options[@]} )))${reset} when done "
PS3="$prompt ${clr}↳${reset} "
    
select opt in "${options[@]}" ; do
    if [[ "${REPLY}" = 'y' || "${REPLY}" = 'Y' ]] ; then
        if [ -z "${SELECTED}" ]; then
            echoMD 'INFO! Invalid option. Nothing selected'
            continue
        else
           break
        fi  
    fi

    if [[ ${REPLY} -lt 1  || ${REPLY} -gt $(( ${#options[@]} )) ]] ; then
        echoMD 'INFO! Invalid option. Must be between 1 and $(( ${#options[@]} )) '
        continue 
    fi

    SELECTED="${opt}"
    echoMD 'INFO! selected *${SELECTED}*'
    if utilityAskYesNO 'OK with choice' ; then
        break
    else
        continue
    fi
done
eval ${rtrn}="\"${SELECTED}\""
return 0
}

function setPassword(){
    unset password
    prompt="Enter Password:"
    while IFS= read -p "$prompt" -r -s -n 1 char
    do
        if [[ $char == $'\0' ]]
        then
            break
        fi
        prompt='*'
        password+="$char"
    done
    echo "Done. Password=$password"
}

function chkRoot(){
local  myReturn='OK'
local thisUserID=$( id -u ) 
if [[ $thisUserID = 0 ]] ; then
    echo 'script running as root'
    return $thisUserID
else
    echo 'script *not* running as root'
    return $thisUserID
fi
}



#PROPERTY FILES

function utilitySetProperty(){
local file="${PROJECT_PROPERTIES_FILE}"
local key="${1}"
local value="${2}"

local chk=$( grep "${key}" ${file} )
# replace line in place
if [[ -z "${chk}" ]]
then
    echo "${key}='${value}'" >> ${file}
else
  toReplace="^(${key}).*$"
  replaceWith="(${key})='${value}'"
  sed i "s|toReplace|${replaceWith}/g"  ${file}
fi
chk=$( grep "${key}='${value}'" ${file}  )
if [ -n "${chk}" ] ; then
    return 0
else
    return 1
fi   
}


function afterReadClear(){
local count=0
local max=$( tput cols)
echo '' #a new line
while ((  count < max )) ; do
    (( count++ ))
    sleep .03
    echo -en "☼"
done
read -t 2 -p "Hit ENTER or wait few seconds"
clear
}

function foldr(){  
fold -w $( tput cols ) -s
}

function echoLine(){
local line=$1
if [[ -z $line ]] ; then
 line='-'
fi
printf '%*s' "$(tput cols)" '' | tr ' ' ${line}
#eval echo $( printf '%*s' "$(tput cols)" '' | tr ' ' '-' )
}

function echoMD(){
    local text="${@}"
	eval echo "$(echo ${text})"
	return 0


    function txtReset(){
        setClr 'bgDefault'
        setClr 'fgDefault'
        #tput ed
    }
    
    function txtHeading(){
        local text="${@}"
        setClr 'bgHeader'
        setClr 'fgHeader'
        tput el
        #tput  cud 2;
        #txtBold 'ins'
        #txtUnderline 'ins'
        txtCentre ${text}
        #txtUnderline 'del'
        #txtBold 'del'
        #tput  cud 2;
        printf '%*s' "$(tput cols)" '' | tr ' ' -
        txtReset
    }
    #
    ##emphasis
    function txtEmphasis(){
        local color='fgGreenDark'
        local text="${@}"
        setClr ${color}
        txtInline ${text}
        txtReset
    }
    
    function txtStrongEmphasis(){
        local color='fgGreenDark'
        local text="${@}"
        txtUnderline 'ins'
        setClr ${color}
        txtInline ${text}
        txtUnderline 'del'
        txtReset
    }
    
    function txtInfo(){
        local color='fgYellowDark' 
        setClr ${color}
        txtInline ' ℹ  ➤'
        txtReset
    }
    
    function txtTask(){
        local color='fgCyanLight' 
        setClr ${color}
        txtInline ' ⚡ '
        txtReset
    }
    
    function txtWait(){
        local color='fgMagentaLight' 
        setClr ${color}
        txtInline ' ⌛ '
        txtReset
    }
    
    function txtDone(){
        local color='fgCyanLight' 
        setClr ${color}
        txtInline ' ➥ '
        txtReset
    }
    
    function txtSuccess(){
        local color='fgGreenLight' 
        setClr ${color}
        txtInline ' ✓ SUCCESS! '
        txtReset  
    }
    
    function txtFailure(){
        local color='fgRedLight' 
        setClr ${color}
        txtInline ' ✗ FAILURE! '
        txtReset  
    }
    
    function txtOK(){
        local color='fgGreenLight' 
        setClr ${color}
        txtInline ' ☻ '
        txtReset
    }   
        
    function txtTick(){
        local color='fgGreenLight' 
        setClr ${color}
        txtInline ' ✓ '
        txtReset
    }
    
    function txtCheck(){
        local color='fgYellowLight' 
        local text=' ☐ CHECK: '
        setClr ${color}
        txtInline ${text}
        txtReset
    }
    
    
    function txtYep(){
        local color='fgGreenDark' 
        setClr ${color}
        txtInline ' ☑ YEP! '
        txtReset
    }
    
    function txtNope(){
        local color='fgRedLight' 
        local text=' ☒ NOPE! '
        setClr ${color}
        txtInline ${text}
        txtReset
    }
    
    function txtFin(){
        local color='fgBlueDark' 
        local text=' FIN! ☼ ☼ ☼ '
        setClr ${color}
        txtInline ${text}
        txtReset
    }
    
    function txtInline(){
        local text="${@}"  
        echo -en "${text}"
    }
    
    function txtBlock(){
        local text="${@}"
        echo -e "  ${text}  "
    }
    
    function txtBold(){
        local i=${1}
        case ${i} in
         'ins'  ) tput smso ;;
         'del'  ) tput rmso ;;
          *) tput smul ;;
        esac 
    }
    
    function txtUnderline(){
        local i=${1}
        case ${i} in
         'ins'  ) tput smul ;;
         'del'  ) tput rmul ;;
          *) tput smul ;;
          
        esac  
    }
    
    function txtUL(){
        '\u2620'
    }
    
    function txtCentre(){
        local text="${@}"
        local colomns=$( tput cols )
        local wordCount=$(echo ${text} | wc -c )
        local num=$(( (${colomns} - ${wordCount} )/2 ))
        local start=$(( ${num} + ${wordCount} ))
        tput cud 1
        tput el
        tput cuf ${num}
        txtInline ${text}
        tput cud 1
        tput cub ${start}
    }
   
# return  
eval echo "$(
    echo ${text} |
    sed -r "s/\*\*([^\*]+)\*\*/\$\( txtStrongEmphasis \1\ \)/g" |
    sed -r "s/\*([^\*]+)\*/\$\( txtEmphasis \1\ \)/g" |
    sed -r "s/TASK!/\$\( txtTask \)/g" |
    sed -r "s/WAIT!/\$\( txtWait \)/g" |
    sed -r "s/DONE!/\$\( txtDone \)/g" |
    sed -r "s/CHECK!/\$\( txtCheck \)/g" |
    sed -r "s/YEP!/\$\( txtYep \)/g" |
    sed -r "s/NOPE!/\$\( txtNope \)/g" |
    sed -r "s/INFO!/\$\( txtInfo \)/g" |
    sed -r "s/SUCCESS!/\$\( txtSuccess \)/g" |
    sed -r "s/FAILURE!/\$\( txtFailure \)/g" |
    sed -r "s/OK!/\$\( txtOK \)/g" |
    sed -r "s/TICK!/\$\( txtTick \)/g" |
    sed -r "s/FIN!/\$\( txtFin \)/g" |
    sed -r "s/#([^\*]+)#/\$\( txtHeading \1\ \)/g"  
    )"
    
}

function setClr(){
local color=${1}
case ${color} in
  'bgCode' ) tput setab 7 ;;
  
  'bgHeader' ) tput setab 8 ;;
  'fgHeader' ) tput setaf 11 ;;
  
  'bgDefault' ) tput setab 0 ;;
  'fgDefault' ) tput setaf 15 ;;
  
  'fgBlackDark'  ) tput setaf 0 ;;
  'fgRedDark'    ) tput setaf 1 ;;
  'fgGreenDark'  ) tput setaf 2 ;;
  'fgYellowDark' ) tput setaf 3 ;;
  'fgBlueDark'   ) tput setaf 4 ;;
  'fgMagentaDark') tput setaf 5 ;;
  'fgCyanDark' ) tput setaf 6 ;;
  'fgWhiteDark' ) tput setaf 7 ;;
  'fgBlackLight' ) tput setaf 8 ;;
  'fgRedLight'    ) tput setaf 9 ;;
  'fgGreenLight'  ) tput setaf 10 ;;
  'fgYellowLight' ) tput setaf 11 ;;
  'fgBlueLight'   ) tput setaf 12 ;;
  'fgMagentaLight') tput setaf 13 ;;
  'fgCyanLight' ) tput setaf 14 ;;
  'fgWhiteLight' ) tput setaf 15 ;;
esac
}


#http://vim.wikia.com/wiki/256_colors_in_vim
#
#if [ "$TERM" = "xterm" ] ; then
#    if [ -z "$COLORTERM" ] ; then
#        if [ -z "$XTERM_VERSION" ] ; then
#            echo "Warning: Terminal wrongly calling itself 'xterm'."
#        else
#            case "$XTERM_VERSION" in
#            "XTerm(256)") TERM="xterm-256color" ;;
#            "XTerm(88)") TERM="xterm-88color" ;;
#            "XTerm") ;;
#            *)
#                echo "Warning: Unrecognized XTERM_VERSION: $XTERM_VERSION"
#                ;;
#            esac
#        fi
#    else
#        case "$COLORTERM" in
#            gnome-terminal)
#                # Those crafty Gnome folks require you to check COLORTERM,
#                # but don't allow you to just *favor* the setting over TERM.
#                # Instead you need to compare it and perform some guesses
#                # based upon the value. This is, perhaps, too simplistic.
#                TERM="gnome-256color"
#                ;;
#            *)
#                echo "Warning: Unrecognized COLORTERM: $COLORTERM"
#                ;;
#        esac
#    fi
#fi
#
#SCREEN_COLORS="`tput colors`"
#if [ -z "$SCREEN_COLORS" ] ; then
#    case "$TERM" in
#        screen-*color-bce)
#            echo "Unknown terminal $TERM. Falling back to 'screen-bce'."
#            export TERM=screen-bce
#            ;;
#        *-88color)
#            echo "Unknown terminal $TERM. Falling back to 'xterm-88color'."
#            export TERM=xterm-88color
#            ;;
#        *-256color)
#            echo "Unknown terminal $TERM. Falling back to 'xterm-256color'."
#            export TERM=xterm-256color
#            ;;
#    esac
#    SCREEN_COLORS=`tput colors`
#fi
#if [ -z "$SCREEN_COLORS" ] ; then
#    case "$TERM" in
#        gnome*|xterm*|konsole*|aterm|[Ee]term)
#            echo "Unknown terminal $TERM. Falling back to 'xterm'."
#            export TERM=xterm
#            ;;
#        rxvt*)
#            echo "Unknown terminal $TERM. Falling back to 'rxvt'."
#            export TERM=rxvt
#            ;;
#        screen*)
#            echo "Unknown terminal $TERM. Falling back to 'screen'."
#            export TERM=screen
#            ;;
#    esac
#    SCREEN_COLORS=`tput colors`
#fi
