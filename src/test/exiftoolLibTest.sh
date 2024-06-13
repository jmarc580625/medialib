#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${exiftoolLib+x} ]  && source ${LIB_PATH}/exiftoolLib

#-------------------------------------------------------------------------------
# function list
: '
getMetaData +file
getVideoSize +file
getVideoWidth +file
getVideoHeight +file
getVideoDuration +file
getGeoTag +file
'

#-------------------------------------------------------------------------------
testResourceDirectory=${@:-${RESOURCE_TEST_DIR}}
inListMode || checkDir "${testResourceDirectory}"
readonly controlingIsInteger=(isInteger '')

#-------------------------------------------------------------------------------
# testing
# test suite naming
suiteStart exiftoolLib "exiftool utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getMetaData "" "get exif metadata from media file" && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controling=(equal "")
  local controled=(${function2Test} ${fileName} XXX)
  controlFunction "${EXPECT_PASS}" controling controled

  local controling=(match '^[1-9][0-9]+x[1-9][0-9]+$')
  local controled=(${function2Test} ${fileName} ImageSize)
  controlFunction "${EXPECT_PASS}" controling controled

  local controling=(match "[0-9]*")
  local controled=(${function2Test} ${fileName} ImageWidth)
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoSize "" "get picture size from media file" && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controling=(match '^[1-9][0-9]+x[1-9][0-9]+$')
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controling controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoWidth  "" "get picture width from media file" && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoHeight "" "get picture height from media file" && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getVideoDuration "" "get video duration from media file"  && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingIsInteger controled

 } && __test__ ; itemEnd

 #-------------------------------------------------------------------------------
 #forceTest=true
 #setTraceOn
 itemStart getGeoTag  "" "get exif geotag from media file" && __test__() {

   local results=('G' '')
   local controling=(inArray results)
   
   local controling=(equal "G")

   local fileName="${testResourceDirectory}/movie+geotag.mp4"
   local controled=(${function2Test} ${fileName})
   controlFunction "${EXPECT_PASS}" controling controled

   local fileName="${testResourceDirectory}/picture+geotag.jpg"
   local controled=(${function2Test} ${fileName})
   controlFunction "${EXPECT_PASS}" controling controled

   local controling=(equal "")

   local fileName="${testResourceDirectory}/movie.mp4"
   local controled=(${function2Test} ${fileName})
   controlFunction "${EXPECT_PASS}" controling controled

   local fileName="${testResourceDirectory}/movie.mp4"
   local controled=(${function2Test} ${fileName})
   controlFunction "${EXPECT_PASS}" controling controled

  } && __test__ ; itemEnd

#-------------------------------------------------------------------------------

suiteEnd
