#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${timerLib+x} ]    && source ${LIB_PATH}/timerLib.sh

#-------------------------------------------------------------------------------
# list of function to test
: '
timerReset
timerTop
timerStop
timerGet
timerIsStarted
timerGetStartTime
timerGetDuration
'
#-------------------------------------------------------------------------------
# settings
declare -a timerList
timerList+=("")
timerList+=(FUBAZ)

#-------------------------------------------------------------------------------
# test suite naming
suiteStart timerLib

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
  itemStart  timerGet && __test__() {

  local controling=(equal '')
  for timerName in "${timerList[@]}" ; do
    local controled=(${function2Test} "${timerName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerGetDuration && __test__() {

  local controling=(equal '')
  for timerName in "${timerList[@]}" ; do
    local controled=(${function2Test} "${timerName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isTimerStarted && __test__() {

  for timerName in "${timerList[@]}" ; do
    local controling=(${function2Test} "${timerName}")
    controlValue "${EXPECT_FAIL}" controling ''
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerReset && __test__() {

  local controling=(equal ok)
  for timerName in "${timerList[@]}" ; do
    ${function2Test} ${timerName}
    local controling=(isTimerStarted "${timerName}")
    controlValue "${EXPECT_PASS}" controling ''
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerGetStartTime && __test__() {

  local controling=(differ '')
  for timerName in "${timerList[@]}" ; do
    local controled=(${function2Test} "${timerName}")
    controlFunction "${EXPECT_PASS}" controling controled
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerGet && __test__() {

  local controling=(eq 0)
  for timerName in "${timerList[@]}" ; do
    if isTimerStarted "${timerName}" ; then
      local controled=(${function2Test} "${timerName}")
      controlFunction "${EXPECT_PASS}" controling controled
    fi
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerGetDuration "_VeryShort" && __test__() {

  local p0="00:00:00"
  local p0n="00:00:00.[0-9]+"
  local tn=VERY_SHORT

  timerReset $tn
  timerTop   $tn

  local controling=(match $p0)
  local controled=(${function2Test} $tn)
  controlFunction "${EXPECT_PASS}" controling controled

  local controling=(match $p0n)
  local controled=(${function2Test} $tn nano)
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerGetDuration "_b" && __test__() {

  local p0="00:00:00"
  local p0n="00:00:00.[0-9]+"

  for timerName in "${timerList[@]}" ; do
    if isTimerStarted "${timerName}" ; then
      local controling=(equal $p0)
      local controled=(${function2Test} "${timerName}")
      controlFunction "${EXPECT_PASS}" controling controled

      local controling=(match $p0n)
      local controled=(${function2Test} "${timerName}" nano)
      controlFunction "${EXPECT_PASS}" controling controled
    fi
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerTop && __test__() {

  local matchPN=(match '^[1-9][0-9]*.[0-9]+$')
  local matchPF=(match '^[0-9]{2}:[0-9]{2}:[0-9]{2}$')
  local matchPFN=(match '^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+$')
  local eqZero=(eq 0)

  for timerName in "${timerList[@]}" ; do
    local tmGtDrt=(timerGetDuration "${timerName}")
    local tmGtDrtNano=(timerGetDuration "${timerName}" nano)

    local t0=$(timerGet "${timerName}")
    controlValue "${EXPECT_PASS}" eqZero t0

    ${function2Test}
    local t1=$(timerGet "${timerName}")
    controlValue "${EXPECT_PASS}" matchPN t1
    controlFunction "${EXPECT_PASS}" matchPF tmGtDrt
    controlFunction "${EXPECT_PASS}" matchPFN tmGtDrtNano

    ${function2Test}
    t2=$(timerGet "${timerName}")
    controlValue "${EXPECT_PASS}" matchPN t2
    local controling=(differ "$t1")
    controlValue "${EXPECT_PASS}" controling t2
    controlFunction "${EXPECT_PASS}" matchPF tmGtDrt
    controlFunction "${EXPECT_PASS}" matchPFN tmGtDrtNano
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart timerStop && __test__() {

  for timerName in "${timerList[@]}" ; do
    local controling=(isTimerStarted "${timerName}")
    controlValue "${EXPECT_PASS}" controling ''
    ${function2Test} "${timerName}"
    controlValue "${EXPECT_FAIL}" controling ''
  done

} && __test__ ; itemEnd
