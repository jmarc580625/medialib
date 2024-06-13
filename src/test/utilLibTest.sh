#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${_protoLib+x} ]  && source ${LIB_PATH}/utilLib

#-------------------------------------------------------------------------------
# list of function to test
: '
checkFullAccessFile
checkReadAccessFile
checkWriteAccessFile
checkIsRegularFile
'

#-------------------------------------------------------------------------------
testResourceDirectory=${@:-${RESOURCE_TEST_DIR}}
inListMode || checkDir "${testResourceDirectory}"

#-------------------------------------------------------------------------------
# test suite naming
suiteStart utilLib "utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart checkFullAccessFile && __test__() {

  local controling1=(equal 1)
  local controling0=(equal 0)
  
  local fileName="${testResourceDirectory}/fakeFileName.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/aDirectory"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessNone.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessReadOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessWriteOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessReadWrite.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

} && __test__ ; itemEnd


#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart checkReadAccessFile && __test__() {

  local controling1=(equal 1)
  local controling0=(equal 0)
  
  local fileName="${testResourceDirectory}/fakeFileName.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/aDirectory"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessNone.txt"
 local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessReadOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

  local fileName="${testResourceDirectory}/accessWriteOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessReadWrite.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart checkWriteAccessFile && __test__() {

  local controling1=(equal 1)
  local controling0=(equal 0)
  
  local fileName="${testResourceDirectory}/fakeFileName.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/aDirectory"
 local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessNone.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessReadOnly.txt"
 local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessWriteOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

  local fileName="${testResourceDirectory}/accessReadWrite.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

} && __test__ ; itemEnd


#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart checkIsRegularFile && __test__() {

  local fileName="${testResourceDirectory}/fakeFileName.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/aDirectory"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_FAIL}" controled

  local fileName="${testResourceDirectory}/accessNone.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

  local fileName="${testResourceDirectory}/accessReadOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

  local fileName="${testResourceDirectory}/accessWriteOnly.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

  local fileName="${testResourceDirectory}/accessReadWrite.txt"
  local controled=(${function2Test} ${fileName})
  controlFunctionRC "${EXPECT_PASS}" controled

} && __test__ ; itemEnd


#-------------------------------------------------------------------------------
suiteEnd
