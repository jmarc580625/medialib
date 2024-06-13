#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under test
[ -z ${videoSizingLib+x} ]  && source ${LIB_PATH}/videoSizingLib

#-------------------------------------------------------------------------------
# list of function to test
: '
<width>  : [numeric]
<height> : [numeric]
<size>   : <width> x <height>

getAspectRatio      <width> <height>
getAspectRatio      <size>

getNewVideoSize     <width> <height> (<oversize> (<strategy>))
getNewVideoSize     <size> (<oversize> (<strategy>))

getVideoRatio       <width> <height>
getVideoRatio       <size>

getVideoOrientation <width> <height>
getVideoOrientation <size>

getVideoSurface     <width> <height>
getVideoSurface     <size>

getVideoSizeDiff    <width> <height> <width> <height>
getVideoSizeDiff    <size> <size>
getVideoSizeDiff    <size> <width> <height>
getVideoSizeDiff    <width> <height> <size>

getVideoSizeRatio   <width> <height> <width> <height>
getVideoSizeRatio   <size> <size>
getVideoSizeRatio   <size> <width> <height>
getVideoSizeRatio   <width> <height> <size>
'

#-------------------------------------------------------------------------------
# test suite naming
suiteStart videoSizingLib

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getAspectRatio && __test__() {

  local -a  w           h           r
            w+=(1690) ; h+=(240)  ; r+=(16x9)
            w+=(540)  ; h+=(420)  ; r+=(5x4)
            w+=(320)  ; h+=(245)  ; r+=(4x3)
            w+=(400)  ; h+=(400)  ; r+=(1x1)
            w+=(1960) ; h+=(890)  ; r+=(16x9)
            w+=(1690) ; h+=(1024) ; r+=(16x10)

  for (( i=0 ; i<${#r[@]} ; i++ )) ; do
    local width=${w[i]}
    local height=${h[i]}
    local ratio=${r[i]}
    local controling=(equal "${ratio}")
    local controled=(${function2Test} "${width}" "${height}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getNewVideoSize && __test__() {

  local -a  w           h           n
            w+=(800)  ; h+=(400)  ; n+=(800x450)
            w+=(400)  ; h+=(800)  ; n+=(450x800)
            w+=(800)  ; h+=(440)  ; n+=(800x450)
            w+=(450)  ; h+=(800)  ; n+=(450x800)

  for (( i=0 ; i<${#w[@]} ; i++ )) ; do
    local width=${w[i]}
    local height=${h[i]}
    local newSize=${n[i]}
    local controling=(equal "${newSize}")
    local controled=(${function2Test} "${width}" "${height}")
    controlFunction "${EXPECT_PASS}" controling controled
    local controled=(${function2Test} "${width}x${height}")
    controlFunction "${EXPECT_PASS}" controling controled
  done
exit
local -a  s               n               o           t
          w+=(810x455)  ; n+=(768x432)  ; o+=(yes)  ; t+=(${TARGET_LOWER})
          w+=(810x455)  ; n+=(768x432)  ; o+=(yes)  ; t+=()
          w+=(810x455)  ; n+=(800x450)  ; o+=(no)   ; t+=(${TARGET_LOWER})
          w+=(810x455)  ; n+=(800x450)  ; o+=()     ; t+=()
          w+=(810x455)  ; n+=(832x468)  ; o+=(no)   ; t+=(${TARGET_UPPER})
          w+=(810x455)  ; n+=(864x486)  ; o+=(yes)  ; t+=(${TARGET_UPPER})

          w+=(320x240)  ; n+=(304x228)  ; o+=(yes)  ; t+=(${TARGET_LOWER})
          w+=(320x240)  ; n+=(320x240)  ; o+=(no)   ; t+=(${TARGET_LOWER})
          w+=(320x240)  ; n+=(320x240)  ; o+=()     ; t+=()
          w+=(320x240)  ; n+=(320x240)  ; o+=(no)   ; t+=(${TARGET_UPPER})
          w+=(320x240)  ; n+=(336x252)  ; o+=(yes)  ; t+=()
          w+=(320x240)  ; n+=(336x252)  ; o+=(yes)  ; t+=(${TARGET_UPPER})

  for (( i=0 ; i<${#s[@]} ; i++ )) ; do
    local size=${s[i]}
    local newSize=${n[i]}
    local overSize=${o[i]}
    local target=${t[i]}
    local controling=(equal "${newSize}")
    local controled=(${function2Test} "${size}" "${overSize}" "${target}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getVideoRatio && __test__() {

  local x1=800
  local x2=400
  local s1="${x1}x${x2}"
  local s2="${x2}x${x1}"
  local s3="16x9"
  local controling=(equal 2)

  local controled=(${function2Test} $x1 $x2)
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} $x2 $x1)
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} $s1)
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} $s2)
  controlFunction "${EXPECT_PASS}" controling controled

  local controling=(match '^[1-9]+[.][0-9]+$')
  local controled=(${function2Test} $s3)
  controlFunction "${EXPECT_PASS}" controling controled
  local controling=(match  '^[1-9]+$')
  local controled=(${function2Test} $s3)
  controlFunction "${EXPECT_FAIL}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getVideoOrientation && __test__() {

  local -a  w           h           s               o
            w+=(400)  ; h+=(800)  ; s+=(400x800)  ; o+=(${ORIENTATION_PORTRAIT})
            w+=(800)  ; h+=(400)  ; s+=(800x400)  ; o+=(${ORIENTATION_LANDSCAPE})
            w+=(400)  ; h+=(400)  ; s+=(400x400)  ; o+=(${ORIENTATION_SQUARE})

  for (( i=0 ; i<${#w[@]} ; i++ )) ; do
    local width=${w[i]}
    local height=${h[i]}
    local size=${s[i]}
    local orientation=${o[i]}
    local controling=(equal "${orientation}")
    local controled=(${function2Test} "${width}" "${height}")
    controlFunction "${EXPECT_PASS}" controling controled
    local controled=(${function2Test} "${size}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getVideoSurface && __test__() {

  local w=40
  local h=80
  local s="${w}x${h}"
  local sc=$(( w * h ))
  local controling=(equal $sc)
  local controled=(${function2Test} "${w}" "${h}")
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${s}")
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getVideoSurfaceDiff && __test__() {

  local w1=40
  local h1=40
  local s1="${w1}x${h1}"
  local sc1=$((w1 * h1))

  local w2=20
  local h2=20
  local s2="${w2}x${h2}"
  local sc2=$((w2 * h2))

  local sdiff=$((sc1 - sc2))
  local controling=(equal $sdiff)

  local controled=(${function2Test} "${w1}" "${h1}" "${w2}" "${h2}")
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${w1}" "${h1}" "${s2}"        )
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${s1}"         "${w2}" "${h2}")
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${s1}"         "${s2}"        )
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
itemStart getVideoSurfaceRatio && __test__() {

  local w1=40
  local h1=40
  local s1="${w1}x${h1}"
  local sc1=$((w1 * h1))

  local w2=20
  local h2=20
  local s2="${w2}x${h2}"
  local sc2=$((w2 * h2))

  local sratio=$(( 100 - (( sc2 * 100 ) / sc1) ))
  local controling=(equal $sratio)

  local controled=(${function2Test} "${w1}" "${h1}" "${w2}" "${h2}")
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${w1}" "${h1}" "${s2}"        )
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${s1}"         "${w2}" "${h2}")
  controlFunction "${EXPECT_PASS}" controling controled
  local controled=(${function2Test} "${s1}"         "${s2}"        )
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
