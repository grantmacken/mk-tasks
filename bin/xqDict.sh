#!/bin/bash

# xq list-modules

# the list of functions available in existdb 

[ -e ../dotfiles/nvim/words/xqExistFunctions.dict ]  && rm ../dotfiles/nvim/words/xqExistFunctions.dict
touch ../dotfiles/nvim/words/xqExistFunctions.dict

xq  list-modules | sort |
while read -r line; do
	if [[ $line != *console ]] ; then
		xq list-functions "$line" | sed 's/$/(/' | tee -a ../dotfiles/nvim/words/xqExistFunctions.dict
	fi
done
