#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper

#-------------------------------------------------------------------------------
# list of function to test
: '
'

#-------------------------------------------------------------------------------
# uncomment when test file are needed
#testResourceDirectory=${@:-${RESOURCE_TEST_DIR}}
#inListMode || checkDir "${testResourceDirectory}"

#-------------------------------------------------------------------------------
# test suite naming
suiteStart mediaLocateAll2 "mediaLocateAll2 command"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart mediaLocateAll2 && __test__() {

  MyOwnVariable=$(echoDollar1 "hello world")

  displayVariable MyOwnVariable
  local controling=(equal foo)
  local controled=(${function2Test} foo)
  controlFunction "${EXPECT_PASS}" controling controled
  controlFunctionRC "${EXPECT_FAIL}" controled
  controlValue equal 1 1

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
