#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${highlightLib+x} ]  && source ${LIB_PATH}/highlightLib

#-------------------------------------------------------------------------------
# list of function to test
: '
getHighlighter
'

#-------------------------------------------------------------------------------
# test commons
controlingIsFunction=(isFunction '')
declare controlingSuccess=(eq ${EXPECT_PASS})
declare hasHighlightPattern="\[1m.\[35m"
declare hasWITHTextPattern="WITH"


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
  local text="WITH COL$i WITH DEFAULT PARAMETERS"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithCustomFunction" && __test__() {

  (( i++ ))
  myHighlight() { echo -e "${bgYellow}${fgBlue}${@}${hlReset}" ; }
  local text="WITH COL$i HAVING CUSTOM HIGHLIGHTER FUNCTION"
  ${function2Test} COL$i myHighlight
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithOutputFile" && __test__() {

  (( i++ ))
  local file=out.txt
  local text="WITH COL$i ON OUTPUT FILE"
  ${function2Test} COL$i "" ${file}
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}"

  controled=(test -e "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasWITHTextPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasHighlightPattern} "${file}")
  controlFunctionRC ${EXPECT_FAIL} controled

  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithOutputFileForcedColor" && __test__() {

  (( i++ ))
  local file=out.txt
  local text="WITH FORCED COL$i ON OUTPUT FILE"
  ${function2Test} COL$i "" ${file} true
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}"

  controled=(test -e "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasWITHTextPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasHighlightPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithRedirectFile" && __test__() {

  (( i++ ))
  file=out.txt
  local text="WITH COL$i ON REDIRECT FILE"
  ${function2Test} COL$i
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" 2>${file}

  controled=(test -e "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasWITHTextPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasHighlightPattern} "${file}")
  controlFunctionRC ${EXPECT_FAIL} controled

  od -c ${file}

  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithRedirectFileForcedColor" && __test__() {

  (( i++ ))
  file=out.txt
  local text="WITH FORCED COL$i ON REDIRECT FILE"
  ${function2Test} COL$i "" "" true
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" 2>${file}

  controled=(test -e "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasWITHTextPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(grep ${hasHighlightPattern} "${file}")
  controlFunctionRC ${EXPECT_PASS} controled

  od -c ${file}

  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithPipe" && __test__() {

  (( i++ ))
  ${function2Test} COL$i
  local text="WITH COL$i ON PIPE"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" |& grep ${hasWITHTextPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

  COL$i "${text}" |& grep ${hasHighlightPattern}
  controlValue ${EXPECT_FAIL} controlingSuccess $?

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithPipeForcedColor" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" "" true
  local text="WITH FORCED COL$i ON PIPE"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" |& grep ${hasWITHTextPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

  COL$i "${text}" |& grep ${hasHighlightPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdout" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1
  local text="WITH COL$i ON STDOUT"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdoutPiped" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1
  local text="WITH COL$i ON STDOUT PIPED"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" | grep ${hasWITHTextPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

  COL$i "${text}" |& grep ${hasHighlightPattern}
  controlValue ${EXPECT_FAIL} controlingSuccess $?

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlighter "_WithStdoutPipedForced" && __test__() {

  (( i++ ))
  ${function2Test} COL$i "" 1 true
  local text="WITH FORCED COL$i ON STDOUT PIPE"
  controlValue ${EXPECT_PASS} controlingIsFunction COL$i

  COL$i "${text}" | grep ${hasWITHTextPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

  COL$i "${text}" |& grep ${hasHighlightPattern}
  controlValue ${EXPECT_PASS} controlingSuccess $?

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
