#!/bin/bash

#Copyright 2015 Google Inc. All rights reserved.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

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

_setjmp_getroot() {
  if [ ! $JMP_ROOT_HINT ] ; then
    echo 1>&2 "\$JMP_ROOT_HINT must be defined!"
    return 1
  fi
  if ! (echo `pwd` | grep "${JMP_ROOT_HINT}")  > /dev/null ; then
    #TODO: this condition can disapear by using getroot()
    if [ -e "./${JMP_ROOT_HINT}" ] ; then
      #we are one level higher than the root hint 
      echo `pwd`"/${JMP_ROOT_HINT}"
      return 0
    fi
    echo 1>&2 "must be within $JMP_ROOT_HINT directory or it must exists in the current directory."
    return 1
  fi
  result=`pwd`
  echo ${result%%${JMP_ROOT_HINT}*}${JMP_ROOT_HINT}
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
    #TODO: this condition can disapear by using getroot() 
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

# tool to enumerate files in the directories of JMP_BOOKMARKS
# at first, let's assume we are at root
jfind () {
  root=`_setjmp_getroot`
  (for dir in "${JMP_BOOKMARKS[@]}" ; do echo ${root}/$dir; done;) | \
    parallel 'echo {} ; ([ ! -e {} ] || find {} -maxdepth 1 -type f)' | \
    sed "s~^${root}/~~g"
}


