#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${highlightLib+x} ]  && source ${LIB_PATH}/highlightLib.sh

#-------------------------------------------------------------------------------
# list of function to test
: '
getHighlighter
'

#-------------------------------------------------------------------------------
# test commons
controlingIsFunction=(isFunction '')
declare  controlingSuccess=(eq ${EXPECT_PASS})
declare controled=(grep -P "[^\x80-\xFF] ${file} >&- 2>&-")

#-------------------------------------------------------------------------------
# test suite naming
suiteStart highlightLib "highlight output"
i=0

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithDefaultParameters" && __test__() {

  (( i++ ))
  ${function2Test} COL$i
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i
  COL$i WITH DEFAULT PARAMETERS


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithCustomFunction" && __test__() {

  (( i++ ))
  myHighlight() { echo -e "${bgYellow}${fgBlue}${@}${hlReset}" ; }
  ${function2Test} COL$i myHighlight
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i
  COL$i WITH CUSTOM HIGHLIGHTER FUNCTION

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithOutputFile" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" ${file}
  COL$i WITH OUTPUT FILE
  local  controling=(isFunction COL$i)
  controlFunction ${EXPECT_PASS} controling
  [[ -e ${file} ]]
  cat ${file}
  controlValue ${EXPECT_FAIL} controlingSuccess $?

  #  grep -P "[^\x80-\xFF]" ${file}
  #  controlValue ${EXPECT_FAIL} controlingSuccess $?

  #od -c ${file}


  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithOutputFileForcedColor" && __test__() {

  (( i++ ))
  local file=out.txt
  ${function2Test} COL$i "" ${file} true
  COL$i WITH FORCED COL$iOR OUTPUT FILE

  cat ${file}
  od -c ${file}
  controlFunction ${EXPECT_PASS} controlingOk controled

  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithRedirectFile" && __test__() {

  (( i++ ))
  file=out.txt
  ${function2Test} COL$i
  COL$i WITH REDIRECT FILE 2>${file}

  cat ${file}
  od -c ${file}
  controlFunction ${EXPECT_FAIL} controlingOk controled

  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithRedirectFileForcedColor" && __test__() {

  (( i++ ))
  file=out.txt
  ${function2Test} COL$i "" "" true
  COL$i WITH FORCED COL$iOR REDIRECT FILE 2>${file}

  cat ${file}
  od -c ${file}
  controlFunction ${EXPECT_PASS} controlingOk controled

  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithPipe" && __test__() {

  (( i++ ))
  ${function2Test} COL$i
  COL$i WITH PIPE  |& more

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithPipeForcedColor" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" "" true
  COL$i WITH FORCED COL$iOR PIPE |& more

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdout" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1
  COL$i WITH STDOUT

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdoutPiped" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1
  COL$i WITH STDOUT PIPED | more

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdoutPipedForced" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1 true
  COL$i WITH FORCED COL$iOR STDOUT PIPE | more

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
