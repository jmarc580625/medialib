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
declare  controling=(ownControler 'dummy')

#-------------------------------------------------------------------------------
# tests
testSuiteStart  testingLib_abort "testing utilities: abort function"
  testItemStart   Item 1
  testItemStart   Item 2
  testItemStart   Item 3
  testItemStart   "test abortion with trace set to see stack"
#  setTraceOn
testSuiteAbort  "abortion test"
  controlValue "${EXPECT_FAIL}" controling "this test step should not be reached"
testSuiteEnd
