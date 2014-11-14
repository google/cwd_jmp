#!/bin/bash

#Copyright 2014 Google, Inc.

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

#See LICENSE file for additional licensing details.

#Disclaimer:  This is not an official Google product.

#See README, for instructions

declare -A JMP_BOOKMARKS

_jmp() {
  #echo "_jmp $1 $@ 2: $2"
  # function to perform bookmark completion
  COMPREPLY=( ${!JMP_BOOKMARKS[@]} )  #default includes all
  if [ $# -gt  0 ] ; then
    COMPREPLY=(`echo ${!JMP_BOOKMARKS[@]} | tr ' ' '\n' | grep "^$2" | tr '\n' ' '`)
  fi
}

complete -F _jmp jmp # jmp is really a forward reference
complete -F _jmp j   # as is j

setjmp () {
  #setjmp bookmark_label relative_path
  #in analagy to setjmp() c function, stores a location for later goto
  if [ $# != 2 ] ; then
    echo "usage: setjmp label path"
    echo "usage: label is the bookmark name"
    return 1
  fi
  JMP_BOOKMARKS[$1]="$2"
}

jmp () {
  #jmp bookmark_label
  #cd to path under current $jmp_root directory indicated by label
  if [ ! $JMP_ROOT_HINT ] ; then
    echo 1>&2 "\$JMP_ROOT_HINT must be defined!"
    return 1
  fi
  if [ "$#" !=  1 ] ; then
    echo 1>&2 "jmp requires 1 argument"
    return 1
  fi
  local dir=`pwd`
  if ! (echo `pwd` | grep "${JMP_ROOT_HINT}")  > /dev/null ; then
    if [ -e "./${JMP_ROOT_HINT}" ] ; then
      #we are one level higher than the root hint
      cd "./${JMP_ROOT_HINT}/${JMP_BOOKMARKS[$1]}"
      return 0
    fi
    echo 1>&2 "must be within $JMP_ROOT_HINT directory or it must exists in the current directory."
    return 1
  fi
  if [ ! ${JMP_BOOKMARKS[$1]+"iskeyintable"} ] ; then
    echo 1>&2 "'$1' not found in bookmark database."
    echo 1>&2 "available bookmarks:"
    echo "${!JMP_BOOKMARKS[@]}" | tr ' ' '\n' | sort | cat 1>&2
    return 1
  fi
  local jmp_root="${dir%${JMP_ROOT_HINT}*}/${JMP_ROOT_HINT}"
  cd "${jmp_root}/${JMP_BOOKMARKS[$1]}"
}

# in case you are into the whole brevity thing.
alias j='jmp'
