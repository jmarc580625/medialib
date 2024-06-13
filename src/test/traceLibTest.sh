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
  getTrace
  setTraceOn
  setTraceOff

  trace
  traceVar
  traceStack

  disableTrace
  enableTrace
'

#-------------------------------------------------------------------------------
# test suite naming
suiteStart traceLib "tracing utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getTrace && __test__() {

  local controling=(match "^(${TRACE_ON}|${TRACE_OFF})$")
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart setTraceOn && __test__() {

  setTraceOn
  local controling=(equal "${TRACE_ON}")
  local controled=(getTrace)
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart setTraceOff && __test__() {

  setTraceOff
  local controling=(equal "${TRACE_OFF}")
  local controled=(getTrace)
  controlFunction "${EXPECT_PASS}" controling controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace && __test__() {

  setTraceOn
  ${function2Test} "setting trace to on"
  ${function2Test} "trace: is " $(getTrace)
  ${function2Test} hello happy taxpayer
  ${function2Test} hello world

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace "_InUpperStackWithNoPriorCall" && __test__() {

  setTraceOn
  function fn3 { p=$1 ; if (( p < 0 )) ; then fn3 $(( p - 1 )) ; else  trace top ; fi ; }
  fn3 $(getRandom 10)

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace "_InUpperStackWithInterimPriorCall" && __test__() {

  setTraceOn
  function fi1 { fi2 ; fi2 ; }
  function fi2 { trace interim ; fi3 ; }
  function fi3 { fi4 ; }
  function fi4 { fi5 ; }
  function fi5 { trace upper ; }
  fi1

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace "_WithSameFunctionCalledTwice" && __test__() {

  setTraceOn
  function ft1 {
    ft2 1 one
    ft2 2 two
    ft2 3 three
  }
  function ft2 { trace "[$@]" ; }
  ft1

} && __test__ ; itemEnd


#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace "_VaryingDepth" && __test__() {

  setTraceOn
  function fs1() { fs2 some data ; fs3 other data ; fs4 last data ; }
  function fs2() { trace [$@] ; }
  function fs3() { trace [$@] ; fs4 more data ; }
  function fs4() { trace [$@] ; }
  fs1

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trace "_InNestedFunctions" && __test__() {

  setTraceOn
  function fn1 { trace [$@] ; fn2 some data ; fn3 other data ; fn4 last data ; }
  function fn2 { trace [$@] ; local recu=$@ ; trace $recu ; trace message 1 ; }
  function fn3 { trace [$@] ; local recu=$@ ; trace $recu ; fn4 more data ; }
  function fn4 { trace [$@] ; local recu=$@ ; trace $recu ; trace message 2 ; }
  fn1 a b c

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart traceVar && __test__() {

  setTraceOn

  traceVar

  local simpleVariable=foo
  traceVar simpleVariable

  local variableWithSpace="hello happy taxpayer"
  traceVar variableWithSpace

  local -n referenceToSimpleVariable=simpleVariable
  traceVar referenceToSimpleVariable

  traceVar undefinedVariable
  unset undefinedVariable

  local -n referenceToUndefinedVariable=undefinedVariable
  traceVar referenceToUndefinedVariable

  local -a indexedArray=(a b c d)
  traceVar indexedArray
  traceVar indexedArray[0]
  traceVar indexedArray[10]
  traceVar indexedArray[a]

  local -n referenceToIndexedArray=indexedArray
  traceVar referenceToIndexedArray

  local -a emptyIndexedArray
  traceVar emptyIndexedArray

  local -A associativeArray=([a]=1 [b]=2 [c]=3 [d]=4)
  traceVar associativeArray
  traceVar associativeArray[a]
  traceVar associativeArray[1]

  local -n referenceToAssociativeArray=associativeArray
  traceVar referenceToAssociativeArray

  local -A EmptyAssociativeArray
  traceVar EmptyAssociativeArray

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart traceStack && __test__() {

  setTraceOn
  function fu1 { fu2 ; }
  function fu2 { fu3 ; }
  function fu3 { fu4 ; }
  function fu4 { ${function2Test} ; }
  fu1

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
