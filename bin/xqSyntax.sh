#!/bin/bash
######################################################
# notes:
# get syntax name under cursor
# echo synIDattr(synID(line("."), col("."), 1), "name")

# xq list-modules

# the list of functions available in existdb 
# non prefixed

# http://www.w3.org/2005/xpath-functions
# http://www.w3.org/2005/xpath-functions/math
outFile='../dotfiles/nvim/syntax/xquery.vim'

[ -e $outFile ]  && rm $outFile
touch $outFile

cat << EOF | tee -a $outFile
"VIM Syntax file
" 
" Language:    XQuery 3.1
" Maintainer:  Grant MacKenzie
" Last Change: 
" Based on fork of https://github.com/james-jw/vim-xquery-syntax
" which is based on fork of https://github.com/jeroenp/vim-xquery-syntax
" 
if exists("b:current_syntax")
   finish
endif

let b:current_syntax = "xquery"

EOF
#non prefixed functions

xpathFunctionsMath="$(
xq list-functions http://www.w3.org/2005/xpath-functions/math |
	xargs |
	sed 's/ /\\\|/g'
	)"

xpathFunctions="$(
xq list-functions http://www.w3.org/2005/xpath-functions |
	xargs |
	sed 's/ /\\\|/g'
	)"

echo '"------------------------------------------------------------------------------------------' | tee -a $outFile
echo '"              NEW STUFF                                                                   ' | tee -a $outFile
echo '"------------------------------------------------------------------------------------------' | tee -a $outFile

# QNames https://www.w3.org/TR/REC-xml-names/#ns-qualname
# UnprefixedName  Unprefixed Qualified Names 
echo "syn match xqXpathFunctions          /(${xpathFunctions})/"     | tee -a $outFile
echo "syn match xqXpathFunctionsMath      /(${xpathFunctionsMath})/" | tee -a $outFile

echo "syn match xqTransformFunctions    /transform:( \
$(xq list-functions http://www.w3.org/1999/XSL/Transform | \
cut -d: -f2 | \
xargs | \
sed 's/ /\\\|/g'))/" >> $outFile

# w3c prefixed Qualified Names

for name in "( map array )" 
do
	xq  list-modules | grep "http://www.w3.org/2005/xpath-functions/${name}" | sort |
	while read -r line; do
		prefix=$( echo $line |  grep -oP '\w+$')
		echo "syn match xqXpathFunctions${prefix^}    /${prefix}:($(
		xq list-functions "$line" |
		cut -d: -f2 |
		xargs |
		sed 's/ /\\\|/g'
		))/" | tee -a $outFile
	done
done

names=( exist expath exquery )
# Prefixed Qualified Names 
for name in "${names[@]}"
do
	xq  list-modules | grep "http://${name}" | sort |
	while read -r line; do
		if [[ $line != *console ]] ; then
			prefix=$( echo $line |  grep -oP '\w+$')
			echo "syn match xq${name^}${prefix^} /${prefix}:($(
			xq list-functions "$line" |
			cut -d: -f2 |
			xargs |
			sed 's/ /\\\|/g'
			))/" | tee -a $outFile
		fi
	done
done


# syntax match xqURL  /https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*/
# hi def link  xqURL    htmlLink


cat << EOF | tee -a $outFile


"-----------------
" PredefinedEntity
"
" &amp;
" ^^^^^
"-----------------

syn match  xqPredefinedEntityRef /&\(lt\|gt\|amp\|quot\|apos\);/

hi def link xqPredefinedEntityRef           Special


"-----------------
" DEFAULT STATE
"-----------------

"-----------------
" xquery version '3.1'
" ^^^^^^^^^^^^^^  ^^^
"-------------------

syn region  xqVersionDec  start=/xquery version/ end=/;/  contains=xqStringLiteral
syn region xqStringLiteral start=/\z(['"]\)/ skip=/\\\z1/ end=/\z1/ contained contains=xqVersionNumber

syn match   xqVersionNumber /3\.1/
syn match   xqSeparator /;/

hi def link xqVersionDec     PreProc
hi def link xqVersionNumber  Number
hi def link xqStringLiteral  StringDelimiter
hi def link xqSeparator      Delimiter

EOF


echo '"------------------------------------------------------------------------------------------' | tee -a $outFile
echo '"              COPY OVER OLD FILE                                                          ' | tee -a $outFile
echo '"------------------------------------------------------------------------------------------' | tee -a $outFile

cat << EOF | tee -a $outFile

syn match   xqyQName            /\k\+\(:\k\+\)\?/ contained contains=NONE transparent
"syn region  xqyBlock            start=/{/ end=/}/ contains=ALLBUT,@xqyPrologStatements

syn region  xqyString           start=/\z(['"]\)/ skip=/\\\z1/ end=/\z1/ keepend
"syn region  xqyAttrString       start=/\z(['"]\)/ skip=/\\\z1/ end=/\z1/ contained contains=xqyBlock
syn region  xqyStartTag         start=#<\([= \/]\)\@!# end=#># contains=xqyAttrString
syn region  xqyEndTag           start=#</# end=#># contains=xqyQName

" syn region  jsonProp          start=/\z(['"]\)/ skip=/\\\z1/ end=/\z1[:]/ contained 
syn match   jsonProp            /["']\(\w\|[@_:-]\)*["']:/

syn keyword xqyPrologKeyword    module namespace import at external
syn keyword xqyDecl             declare nextgroup=xqyOption,xqyContext,xqyDeclFun,xqyDeclVar,xqyDeclCons skipwhite
syn keyword xqyDeclCons         construction nextgroup=xqyDeclConsOpt skipwhite
syn keyword xqyDeclConsOpt      strip preserve
syn keyword xqyDeclVar          variable nextgroup=xqyVariable external skipwhite
syn keyword xqyContext          context item skipwhite
syn keyword xqyOption           option skipwhite
syn keyword xqyDeclFun          function nextgroup=xqyFunction skipwhite
syn match   xqyNamespace        /\(\w\|[-_]\)*:/ 

syn match   xqyVariable         /\$\k\+/
syn match   xqyAnnotation       /%\k\+\(:\k\+\)\?/
syn match   xqyFunction         /\k\+\(:\k\+\)\?()/ " FIXME 
syn keyword xqyTypeSigKeyword   as xs nextgroup=xqyType skipwhite
syn match   xqyType             /\k+\(:\k\+\)\?/ contained
syn cluster xqyPrologStatements contains=xqyPrologKeyword,xqyDecl,xqyDeclVar,xyDeclFun,xqyDeclCons,xqyDeclConsOpt

syn keyword xqyFLWOR            for in let where group by order by at count return
syn keyword xqyUpdate           modify copy delete rename insert node nodes into last first before after
syn keyword xqyWindow           tumbling sliding window start when end only

syn keyword xqyConstructor      attribute
syn match   xqyConstructor      /\(element\|comment\|processing-instruction\)\ze\s/

syn keyword xqyConditional      if then else every some
syn keyword xqyConditional      or 
syn keyword xqyConditional      typeswitch 
syn keyword xqyConditional      switch case default
syn keyword xqyConditional      try catch
syn keyword xqyConditional      text not in ftor ftand ftnot any all ordered distance most words same sentence without occurs
syn keyword xqyConditional      using case sensitive diacritics using stemming language stop wildcards score fuzzy thesaurus
syn match   xqyConditional      /contains/
syn keyword xqyMapArrayType     map array

syn match   xqyMap              /\s!\s\|=>/

syn keyword xqyTodo             TODO XXX FIXME contained
syn match   xqyDocKeyword       display /@\(version\|since\|deprecated\|error\|return\|param\|author\|see\)/ contained nextgroup=xqyVariable skipwhite
syn region  xqyDocComment       start="(:\~" end=":)" contains=xqyTodo,xqyDocKeyword,xqyVariable,xqyComment,xqyDocComment,@Spell fold
syn region  xqyComment          start="(\:\(\~\)\@!" end="\:)" contains=xqyTodo,xqyComment,xqyDocComment,@Spell fold
EOF


echo '"------------------------------------------------------------------------------------------' | tee -a $outFile
echo '"              NEW HiLight STUFF                                                           ' | tee -a $outFile
echo '"------------------------------------------------------------------------------------------' | tee -a $outFile

cat << EOF | tee -a $outFile

hi def link xqXpathFunctions        Function
hi def link xqXpathFunctionsMath    Function
hi def link xqTransformFunctions    Function

EOF

for name in  "( map array )"
do
	xq  list-modules | grep "http://${name}" | sort |
	while read -r line; do
		if [[ $line != *console ]] ; then
			prefix=$( echo $line |  grep -oP '\w+$')
			echo "hi def link  xq${name^}${prefix^}   Function" | tee -a $outFile
		fi
	done
done

for name in "${names[@]}"
do
	xq  list-modules | grep "http://${name}" | sort |
	while read -r line; do
		if [[ $line != *console ]] ; then
			prefix=$( echo $line |  grep -oP '\w+$')
			echo "hi def link  xq${name^}${prefix^}   Function" | tee -a $outFile
		fi
	done
done


cat << EOF | tee -a $outFile


EOF

echo '"------------------------------------------------------------------------------------------' | tee -a $outFile
echo '"              COPY OF old HiLight STUFF                                                  ' | tee -a $outFile
echo '"------------------------------------------------------------------------------------------' | tee -a $outFile
cat << EOF | tee -a $outFile
hi def link xqyString           String
hi def link xqyAttrString       String
hi def link xqyStartTag         Question
hi def link jsonProp            Question
hi def link xqyEndTag           Special
hi def link xqyNamespace        Special

hi def link xqyMapArray         Comment
hi def link xqyComment          Comment
hi def link xqyDocComment       Comment
hi def link xqyDocKeyword       SpecialComment
hi def link xqyTodo             Todo

hi def link xqyDecl             Define
hi def link xqyDeclCons         Define
hi def link xqyDeclConsOpt      Define
hi def link xqyDeclFun          Define
hi def link xqyDeclVar          Define
hi def link xqyContext          Define
hi def link xqyOption           Define
hi def link xqyPrologKeyword    PreProc
hi def link xqyTypeSigKeyword   PreProc
hi def link xqyVariableExt      PreProc
hi def link xqyMapArrayType     PreProc

hi def link xqyFLWOR            Keyword
hi def link xqyUpdate           Keyword
hi def link xqyWindow           Keyword
hi def link xqyConstructor      Keyword
hi def link xqyConditional      Conditional

hi def link xqyVariable         Identifier
hi def link xqyAnnotation       Identifier
hi def link xqyMap              Identifier
hi def link xqyType             Type
EOF

