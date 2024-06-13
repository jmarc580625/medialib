#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#ffmpegLib_WithTrace=true
[ -z ${ffmpegLib+x} ]   && source ${LIB_PATH}/ffmpegLib

#-------------------------------------------------------------------------------
# function list
: '
cropSpec2CropWidth
cropSpec2CropHeight
cropSpec2CropSize
cropSpec2CropPosition
setFfmpegQualityMetrics
getFfmpegQualityOption
getFfmpegSeekOption
getFfmpegAdaptativeSeekOption
blackIntroDetect +file
blackExtroDetect +file
getNextIFrameIndex +file
getCropSpec +file
'

#-------------------------------------------------------------------------------
testResourceDirectory=${@:-${RESOURCE_TEST_DIR}}
inListMode || checkDir "${testResourceDirectory}"

#-------------------------------------------------------------------------------
readonly controlingCBR=(match '^-crf[[:space:]][0-9]{1,2}$')
readonly controlingVBR=(match '^-qscale:v[[:space:]][0-9]{1,2}$')
readonly controlingSEEK=(match '^-ss[[:space:]][0-9]*$')
readonly controlingCROP=(match '^crop=[0-9]*:[0-9]*:[0-9]*:[0-9]*$')
readonly controlingINDEX=(match '^[0-9]*.[0-9]*$')

#-------------------------------------------------------------------------------
# test suite naming
suiteStart ffmpegLib

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart cropSpec2CropWidth && __test__() {

  local controling=(equal 1)
  local controled=(${function2Test} 'crop=1:2:3:4')
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart cropSpec2CropHeight && __test__() {

  local controling=(equal 2)
  local controled=(${function2Test} 'crop=1:2:3:4')
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart cropSpec2CropSize && __test__() {

  local controling=(equal '1x2')
  local controled=(${function2Test} 'crop=1:2:3:4')
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart cropSpec2CropPosition && __test__() {

  local controling=(equal '3,4')
  local controled=(${function2Test} 'crop=1:2:3:4')
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart setFfmpegQualityMetrics && __test__() {

  setFfmpegQualityMetrics CBR
  controlValue "${EXPECT_PASS}" controlingCBR FFMPEG_ENCODING_QUALITY_OPTION

  setFfmpegQualityMetrics VBR
  controlValue "${EXPECT_PASS}" controlingVBR FFMPEG_ENCODING_QUALITY_OPTION

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getFfmpegQualityOption "_WithCBRMetrics" && __test__() {

  local -a qm=(CBR VBR)
  local -a qo=(DEFAULT HIGH MEDIUM_HIGH MEDIUM MEDIUM_LOW LOW)
  for metrics in "${qm[@]}" ; do
    setFfmpegQualityMetrics "${metrics}"
    local controling=(equal "${FFMPEG_ENCODING_QUALITY_OPTION}")
    local controled=(${function2Test} DUMMY)
    controlFunction "${EXPECT_PASS}" controling controled
    local controled=(${function2Test} DEFAULT)
    controlFunction "${EXPECT_PASS}" controling controled
    for quality in "${qo[@]}" ; do
      local controled=(${function2Test} ${quality})
      controlFunction "${EXPECT_PASS}" "controling${metrics}" controled
    done
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getFfmpegSeekOption && __test__() {

  local controling=(equal "")
  local -a noSeek=(abx 0 "")
  for seek in "${noSeek[@]}" ; do
    local controled=(${function2Test} ${seek})
    controlFunction "${EXPECT_PASS}" controling controled
  done

  for (( i = 1; i < 10; i++ )); do
    local seek=$(( i * 15 ))
    local controled=(${function2Test} ${seek})
    controlFunction "${EXPECT_PASS}" controlingSEEK controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getFfmpegAdaptativeSeekOption && __test__() {

  local -a noSeek=(abx 0 "")
  local controling=(equal "")
  for seek in "${noSeek[@]}" ; do
    local controled=(${function2Test} ${seek})
    controlFunction "${EXPECT_PASS}" controling controled
  done

  for (( i = 1; i < 10; i++ )); do
    local seek=$i
    local controled=(${function2Test} ${seek})
    controlFunction "${EXPECT_PASS}" controling controled
  done

  for (( i = 2; i < 30; i++ )); do
    local seek=$(( i * 5 ))
    local controled=(${function2Test} ${seek})
    controlFunction "${EXPECT_PASS}" controlingSEEK controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart blackIntroDetect && __test__() {

  local fileName="${testResourceDirectory}/movie+intro.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingINDEX controled

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  local controling=(equal "")
  controlFunction "${EXPECT_PASS}" controling controled  

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart blackExtroDetect && __test__() {

  local fileName="${testResourceDirectory}/movie+extro.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingINDEX controled

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  local controling=(equal "")
  controlFunction "${EXPECT_PASS}" controling controled  

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getNextIFrameIndex && __test__() {

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName}  2)
  controlFunction "${EXPECT_PASS}" controlingINDEX controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getCropSpec && __test__() {

  local fileName="${testResourceDirectory}/movie+blackframe.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingCROP controled

  local fileName="${testResourceDirectory}/movie.mp4"
  local controled=(${function2Test} ${fileName})
  controlFunction "${EXPECT_PASS}" controlingCROP controled  

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
