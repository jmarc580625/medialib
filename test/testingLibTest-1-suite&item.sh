#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh



#-------------------------------------------------------------------------------
# list of function to test
: '
'

#-------------------------------------------------------------------------------
# commons
function ownControler { [[ "$1" == "$2" ]] ; }
function ownFunction { echo $1 ; }
declare  v1=YES
declare  v2=NO
declare  controling=(ownControler "$v1")
declare  controled=(ownFunction "$v1")

#-------------------------------------------------------------------------------
# tests
testSuiteStart emptySuite_ExplicitStartingAndEnding "test-suite: explicit starting and ending"
testSuiteEnd

testSuiteStart suite_ExplicitStartingAndEnding "test-suite and test-item: explicit starting and ending"
  testItemStart emptyItem_ExplicitStartingAndEnding
  testItemEnd
testSuiteEnd

testSuiteStart emptySuite_AutoEndingOnNextSuite "test-suite : auto-ending on next suite starting"

testSuiteStart suite_ExplicitStartingAndEnding "test-item : auto-ending on next item starting"
  testItemStart emptyItem_AutoEndingOnNextItem
  testItemStart emptyItem
  testItemEnd
testSuiteEnd

testSuiteStart suite_ExplicitStartingAndEnding "test-item : auto-ending on suite ending"
  testItemStart emptyItem_AutoEndingOnSuiteEnd
testSuiteEnd

echo "test-suite : auto-starting on first item"
  testItemStart   emptyItem_AutoStartingSuiteOnFirstItem
testSuiteEnd

testSuiteStart suite_AutoStartingItemOnFirstTest "test-item : auto-starting on first test step"
  controlFunction "${EXPECT_PASS}" controling controled
testSuiteEnd

echo "test-suite and test-item: auto-starting on first test step"
  controlFunction "${EXPECT_PASS}" controling controled
testSuiteEnd

testSuiteStart emptySuite_EndingTwice "test-suite : ending twice"
testSuiteEnd
testSuiteEnd

testSuiteStart suite_WithEndingTwiceItem "test-item : ending twice"
  testItemStart emptyItem_EndingTwice
  testItemEnd
  testItemEnd
testSuiteEnd

testSuiteStart suite_TestStatusEqualNumberOfFailure "test-suite : TEST_STATUS giving number of failed test"
  testItemStart item_With2FailedTests
    controlFunction "${EXPECT_PASS}" controling controled
    controlFunction "${EXPECT_FAIL}" controling controled
    controlValue "${EXPECT_PASS}" controling v1
    controlValue "${EXPECT_PASS}" controling v2
testSuiteEnd
status=${TEST_STATUS}
echo "TEST_STATUS=${status}, test" $((( status = 2 )) && echo "succeed='ok'" || echo "succeed='ko'")
