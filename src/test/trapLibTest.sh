#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${trapLib+x} ]  && source ${LIB_PATH}/trapLib

#-------------------------------------------------------------------------------
# list of function to test
: '
trapGetHandler
trapPush
trapPop
trapPrepend
trapAppend
'
#-------------------------------------------------------------------------------
# uncomment when input file is mandatory
#inListMode || chekFiles "$@"

#-------------------------------------------------------------------------------
# testing suite commons
function trapStatus {
  local -n ctrl=$1
  local sigs=(${@:2})
  for (( i=0; i<${#sigs[@]}; i++ )) ; do
    t=${sigs[i]}
    declare trap$t="$(trapGetHandler $t)"
    displayElement trap$t
    local controling=(equal "${ctrl[$i]}")
    controlValue "${EXPECT_PASS}" controling trap$t
  done
}
readonly trapINI='echo "InIt" ;'" echo 'hNdL'"
readonly trapNoF='echo "NoFn TrAp"'
function trapFnc { echo "Fn tRaP" ; }
readonly SIG_1=SIGUSR1
readonly SIG_2=SIGUSR2
readonly SIGKO=SIGPLOP

#-------------------------------------------------------------------------------
# test suite naming
suiteStart trapLib "manage trap handler"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trap "_WithValidSignals" && __test__() {

  local -a e1 e2 e3 e4 e5 e6 e7 e8 e9 e10 e11 e12 e13

  e1+=("") ; e2+=("$trapINI") ; e3+=("$trapINI") ; e4+=("$trapNoF")
  e1+=("") ; e2+=("")         ; e3+=("")         ; e4+=("")
  e1+=("") ; e2+=("")         ; e3+=("")         ; e4+=("")

  e5+=("$trapNoF ; trapFnc") ; e6+=("trapFnc ; $trapNoF ; trapFnc")
  e5+=("trapFnc")            ; e6+=("trapFnc ; trapFnc")
  e5+=("")                   ; e6+=("")

  e7+=("$trapNoF") ; e8+=("trapFnc ; $trapNoF ; trapFnc")
  e7+=("$trapNoF") ; e8+=("trapFnc ; trapFnc")
  e7+=("")         ; e8+=("")

  e9+=("trapFnc ; trapFnc ; $trapNoF ; trapFnc") ; e10+=("$trapNoF")
  e9+=("trapFnc ; trapFnc ; trapFnc")            ; e10+=()
  e9+=("")                                       ; e10+=()

  e11+=("$trapNoF") ; e12+=("$trapINI") ; e13+=("$trapINI")
  e11+=("$trapNoF") ; e12+=("$trapNoF") ; e13+=("")
  e11+=("")         ; e12+=("")         ; e13+=("")

  local sigList="${SIG_1} ${SIG_2}"
  #local sigList="${SIG_1}"

  testStep "E1-Initial trap state (initialized by used libraries):"
  trapStatus e1 ${sigList}

  testStep "E2-Setting messy non-function handler for ${SIG_1} (original state)"
  trap "$trapINI" ${SIG_1}
  trapStatus e2 ${sigList}

  testStep "E3-Pop ${SIG_1} empty stacks (still in original state)"
  trapPop ${SIG_1}
  trapStatus e3 ${sigList}

  testStep "E4-Push non-function handler for ${SIG_1}"
  trapPush "$trapNoF" ${SIG_1}
  trapStatus e4 ${sigList}

  testStep "E5-Append function handler for ${SIG_1} and ${SIG_2}"
  trapAppend trapFnc ${SIG_1} ${SIG_2}
  trapStatus e5 ${sigList}

  testStep "E6-Prepend function handler for ${SIG_1} and ${SIG_2}"
  trapPrepend trapFnc ${SIG_1} ${SIG_2}
  trapStatus e6 ${sigList}

  testStep "E7-Push non-function handler for ${SIG_1} and ${SIG_2}"
  trapPush "$trapNoF" ${SIG_1} ${SIG_2}
  trapStatus e7 ${sigList}

  testStep "E8-Pop both stacks"
  trapPop ${SIG_1} ${SIG_2}
  trapStatus e8 ${sigList}

  testStep "E9-Prepend function handler for ${SIG_1} and ${SIG_2}"
  trapPrepend trapFnc ${SIG_1} ${SIG_2}
  trapStatus e9 ${sigList}

  testStep "E10-Pop both stacks thrice"
  trapPop ${SIG_1} ${SIG_2}
  trapPop ${SIG_1} ${SIG_2}
  trapPop ${SIG_1} ${SIG_2}
  trapStatus e10 ${sigList}

  testStep "E11-Push non-function handler for ${SIG_2}"
  trapPush "$trapNoF" ${SIG_2}
  trapStatus e11 ${sigList}

  testStep "E12-Pop handler state for ${SIG_1} (back to original state)"
  trapPop ${SIG_1}
  trapStatus e12 ${sigList}

  testStep "E13-Pop handler state for ${SIG_2} (back to original state)"
  trapPop ${SIG_2}
  trapStatus e13 ${sigList}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart trap "_WithInvalidSignals" && __test__() {

  local -a i1 i2 i3 i4 i5
  i1+=("") ; i2+=("") ; i3+=("") ; i4+=("") ; i5+=("")

  testStep "I1-Get trap handler for non valid signal"
  trapStatus i1 ${SIGKO}

  testStep "I2-Push trap handler for non valid signal"
  trapPush trapFnc ${SIGKO}
  trapStatus i2 ${SIGKO}

  testStep "I3-Pop trap handler for non valid signal"
  trapPop ${SIGKO}
  trapStatus i3 ${SIGKO}

  testStep "I4-Prepend function handler for valid signal"
  trapPrepend trapFnc ${SIGKO}
  trapStatus i4 ${SIGKO}

  testStep "I5-Append function handler for valid signal"
  trapAppend trapFnc ${SIGKO}
  trapStatus i5 ${SIGKO}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
