#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${logLib+x} ]  && source ${LIB_PATH}/logLib

#-------------------------------------------------------------------------------
# list of function to test
: '
out
info
warning
error
fatal
'

#-------------------------------------------------------------------------------
# uncomment when input file is mandatory
#inListMode || chekFiles "$@"

#-------------------------------------------------------------------------------
# testing
# test suite naming
suiteStart logLib "log messages with highlighted output"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart out && __test__() {

  local file=out.txt
  ${function2Test} unqualified log message on tty
  ${function2Test} unqualified log message on pipe |& more
  ${function2Test} unqualified log message on file 2>${file}
  cat ${file}
  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart info && __test__() {

  local file=out.txt
  ${function2Test} info log message on tty
  ${function2Test} info log message on pipe |& more
  ${function2Test} info log message on file 2>${file}
  cat ${file}
  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart warning && __test__() {

  local file=out.txt
  ${function2Test} warning log message on tty
  ${function2Test} warning log message on pipe |& more
  ${function2Test} warning log message on file 2>${file}
  cat ${file}
  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart error && __test__() {

  local file=out.txt
  ${function2Test} error log message on tty
  ${function2Test} error log message on pipe |& more
  ${function2Test} error log message on file 2>${file}
  cat ${file}
  od -c ${file}
  rm -f ${file}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn

itemStart fatal && __test__() {

  trap "echo TERM signal recieved" TERM
  ${function2Test} error log message on tty

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
