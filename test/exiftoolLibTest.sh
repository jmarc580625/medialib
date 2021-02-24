#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${exiftoolLib+x} ]  && source ${LIB_PATH}/exiftoolLib.sh

#-------------------------------------------------------------------------------
# function list
: '
getMetaData
getVideoSize
getVideoWidth
getVideoHeight
getVideoDuration
'

#-------------------------------------------------------------------------------
inListMode || fileName=$(chekFiles "$@")
readonly controlingIsInteger=(isInteger '')

#-------------------------------------------------------------------------------
# testing
# test suite naming
suiteStart exiftoolLib "exiftool utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getMetaData  && __test__() {

  local controling=(match "")
  local controled=(${function2Test} ${fileName} XXX)
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoSize && __test__() {

  local controling=(match '^[1-9][0-9]+x[1-9][0-9]+$')
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controling controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoWidth  && __test__() {

  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoHeight  && __test__() {

  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoDuration  && __test__() {

  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

 #-------------------------------------------------------------------------------
 #forceTest=true
 #setTraceOn
 itemStart getGeoTag  && __test__() {

   local results=('G' '')
   local controling=(inArray results)
   local controled=(${function2Test} ${fileName})
   controlFunction "${EXPECT_PASS}" controling controled

  } && __test__ ; itemEnd

#-------------------------------------------------------------------------------

suiteEnd
