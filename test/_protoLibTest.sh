#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${_protoLib+x} ]  && source ${LIB_PATH}/_protoLib.sh

#-------------------------------------------------------------------------------
# list of function to test
: '
'

#-------------------------------------------------------------------------------
# uncomment when input file is mandatory
#inListMode || chekFiles "$@"

#-------------------------------------------------------------------------------
# test suite naming
suiteStart _protoLib "template test driver on template library"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollar1 && {

  MyOwnVariable=$(echoDollar1 "hello world")
  displayVariable MyOwnVariable
  controlFunction equal foo ${function2Test} foo
  controlValue equal 1 1

} ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
