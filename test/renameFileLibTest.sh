#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${renameFileLib+x} ] && source ${LIB_PATH}/renameFileLib.sh

#-------------------------------------------------------------------------------
# function list
: '
getNewFileName
getFileNameExtention
getDirectoryName
getFileName
'
#-------------------------------------------------------------------------------
# settings
declare suffix="_X"
declare newExt="fuzz"

declare -a \
fileNames                                   extention           dirname
fileNames+=("")                           ; extention+=("")   ; dirname+=(.)
fileNames+=(" ")                          ; extention+=("")   ; dirname+=(.)
fileNames+=(.)                            ; extention+=("")   ; dirname+=(.)
fileNames+=(..)                           ; extention+=("")   ; dirname+=(.)
fileNames+=(toto)                         ; extention+=("")   ; dirname+=(.)
fileNames+=(toto.txt)                     ; extention+=(txt)  ; dirname+=(.)
fileNames+=(toto.)                        ; extention+=("")   ; dirname+=(.)
fileNames+=(toto..)                       ; extention+=("")   ; dirname+=(.)
fileNames+=(/path/to/file/toto.txt)       ; extention+=(txt)  ; dirname+=(/path/to/file)
fileNames+=(/path/to/file/toto.txt.truc)  ; extention+=(truc) ; dirname+=(/path/to/file)
fileNames+=(/path/to/a.file/toto.txt)     ; extention+=(txt)  ; dirname+=(/path/to/a.file)
fileNames+=(/path/to/a.file/toto.txt.truc); extention+=(truc) ; dirname+=(/path/to/a.file)

declare -a \
filename              basename                    wSufx
filename+=("")      ; basename+=("")            ; wSufx+=("")
filename+=("")      ; basename+=("")            ; wSufx+=("")
filename+=("")      ; basename+=(.)             ; wSufx+=(.)
filename+=(..)      ; basename+=(..)            ; wSufx+=(..)
filename+=(toto)    ; basename+=(toto)          ; wSufx+=(toto${suffix})
filename+=(toto)    ; basename+=(toto.txt)      ; wSufx+=(toto${suffix}.txt)
filename+=(toto)    ; basename+=(toto.)         ; wSufx+=(toto${suffix}.)
filename+=(toto.)   ; basename+=(toto..)        ; wSufx+=(toto.${suffix}.)
filename+=(toto)    ; basename+=(toto.txt)      ; wSufx+=(/path/to/file/toto${suffix}.txt)
filename+=(toto.txt); basename+=(toto.txt.truc) ; wSufx+=(/path/to/file/toto.txt${suffix}.truc)
filename+=(toto)    ; basename+=(toto.txt)      ; wSufx+=(/path/to/a.file/toto${suffix}.txt)
filename+=(toto.txt); basename+=(toto.txt.truc) ; wSufx+=(/path/to/a.file/toto.txt${suffix}.truc)

declare -a \
wExt                                         wSufxExt
wExt+=("")                                 ; wSufxExt+=("")
wExt+=("")                                 ; wSufxExt+=("")
wExt+=(.)                                  ; wSufxExt+=(.)
wExt+=(..)                                 ; wSufxExt+=(..)
wExt+=(toto.${newExt})                     ; wSufxExt+=(toto${suffix}.${newExt})
wExt+=(toto.${newExt})                     ; wSufxExt+=(toto${suffix}.${newExt})
wExt+=(toto.${newExt})                     ; wSufxExt+=(toto${suffix}.${newExt})
wExt+=(toto..${newExt})                    ; wSufxExt+=(toto.${suffix}.${newExt})
wExt+=(/path/to/file/toto.${newExt})       ; wSufxExt+=(/path/to/file/toto${suffix}.${newExt})
wExt+=(/path/to/file/toto.txt.${newExt})   ; wSufxExt+=(/path/to/file/toto.txt${suffix}.${newExt})
wExt+=(/path/to/a.file/toto.${newExt})     ; wSufxExt+=(/path/to/a.file/toto${suffix}.${newExt})
wExt+=(/path/to/a.file/toto.txt.${newExt}) ; wSufxExt+=(/path/to/a.file/toto.txt${suffix}.${newExt})

#-------------------------------------------------------------------------------
# testing
# test suite naming
suiteStart renameFileLib "file renaming utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getNewFileName && __test__() {

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${wSufx[i]}")
    local controled=(${function2Test} "${fileName}" "${suffix}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${wSufxExt[i]}")
    local controled=(${function2Test} "${fileName}" "${suffix}" "${newExt}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${wExt[i]}")
    local controled=(${function2Test} "${fileName}" "" "${newExt}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getNewFileName "_WithExitingFile" && __test__() {

  local existingFileName=fooBar.txt
  local renamedFileName=fooBar.abc
  local newExt=txt

  touch ${existingFileName}

  local fileName1=$(${function2Test} "${renamedFileName}" "" "${newExt}")
  local controling=(equal fooBar-1.txt)
  controlValue "${EXPECT_PASS}" controling fileName1

  touch ${fileName1}

  local fileName2=$(${function2Test} "${renamedFileName}" "" "${newExt}")
  local controling=(equal fooBar-2.txt)
  controlValue "${EXPECT_PASS}" controling fileName2

  rm -f fooBar-?.txt

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getFileNameExtention && __test__() {

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${extention[i]}")
    local controled=(${function2Test} "${fileName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getDirectoryName && __test__() {

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${dirname[i]}")
    local controled=(${function2Test} "${fileName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getFileName && __test__() {

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${filename[i]}")
    local controled=(${function2Test} "${fileName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getBaseName && __test__() {

  for (( i=0 ; i<${#fileNames[@]} ; i++ )) ; do
    local fileName=${fileNames[i]}
    local controling=(equal "${basename[i]}")
    local controled=(${function2Test} "${fileName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
