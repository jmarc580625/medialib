#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(cd ${TESTDRIVER_HOME}/../lib ; pwd)
# import test driver helper
#testingLib_WithTrace=true
controlerLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper.sh
#import library under testing
[ -z ${controlerLib+x} ]  && source ${LIB_PATH}/controlerLib.sh

#-------------------------------------------------------------------------------
# list of function to test
: '
'

#-------------------------------------------------------------------------------
# tests utilities
readonly MSG_PASSING=PASS
readonly MSG_FAILING=FAIL
readonly TEST_PASSING=0
readonly TEST_FAILING=1
readonly FUNCTION_OK=ok
readonly FUNCTION_KO=ko

function _reportHighlight {
  echo $@ | \
  sed \
    -e "s/\(${FUNCTION_OK}\)/${fgGreen}\1${hlReset}/g"  \
    -e "s/\(${FUNCTION_KO}\)/${fgRed}\1${hlReset}/g"    \
    -e "s/\(${MSG_PASSING}\)/${fgLightGreen}\1${hlReset}/g"  \
    -e "s/\(${MSG_FAILING}\)/${fgLightRed}\1${hlReset}/g"
}

getHighlighter _TESTCONTROLER_OUT _reportHighlight
declare fnR
fnR[0]=${FUNCTION_OK}
fnR[1]=${FUNCTION_KO}
declare tstR
tstR[0]=${MSG_PASSING}
tstR[1]=${MSG_FAILING}
tstR[2]=${MSG_PASSING}

function value {
#  x=$- ; [[ $x =~ x ]] && set +x
  if [[ "$1" =~ ^[[:space:]]*$ ]] ; then
    echo \'"$1"\'
  elif [[ $(declare -p "$1" 2>&-) =~ ^declare[[:space:]]-[aA] ]] ; then
    declare -n _a=$1;
    echo \'"(${_a[@]})"\'
  elif [[ $(declare -p "$1" 2>&-) =~ ^declare[[:space:]]- ]] ; then
    declare -n _v=$1; echo \'$_v\'
  else
    echo \'$1\'
  fi
#  [[ $x =~ x ]] && set -x
}
function report {
#  x=$- ; [[ $x =~ x ]] && set +x
  declare -i testResult="$1+$2"
  _TESTCONTROLER_OUT "test ${tstR[${testResult}]}:function ${fnR[$1]}:${@:3}"
#  [[ $x =~ x ]] && set -x
}

#-------------------------------------------------------------------------------
function controlMatrix {
  local -n expectMatrix=$1
  local -n value2Matrix=$3
  local -n value1Matrix=$2
  for (( i=0 ; i<${#expectMatrix[@]}; i++ )) ; do
    local value1=${value1Matrix[i]}
    local value2=${value2Matrix[i]}
    local expect=${expectMatrix[i]}
    ${function2Test} "${value1}" "${value2}" ; report $? ${expect} "${function2Test}:$(value value1) $(value value2)"
  done
}
#-------------------------------------------------------------------------------

# tests
#-------------------------------------------------------------------------------
# test suite initialisation
suiteStart controlerLib "controler utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlF && __test__() {

  function f { echo $1 ; }
  local var=a

  local controling=(equal "${var}")
  ${function2Test} controling f "${var}" ; report $? ${TEST_PASSING} "${function2Test}:$(value controling) $(value var)"

  local controling=(differ "${var}")
  ${function2Test} controling f "${var}" ; report $? ${TEST_FAILING} "${function2Test}:$(value controling) $(value var)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart control && __test__() {

  function f { echo $1 ; }
  local val=a

  local controling=("equal" "${val}")
  local controled=("f" "${val}")
  ${function2Test} controling controled ; report $? ${TEST_PASSING} "${function2Test}:$(value controling) $(value controled)"

  local controling=("differ" "${val}")
  local controled=("f" "${val}" x y z)
  ${function2Test} controling controled ; report $? ${TEST_FAILING} "${function2Test}:$(value controling) $(value controled)"

  local controling=("differ" "${val}")
  local -n var=val
  ${function2Test} controling var ; report $? ${TEST_FAILING} "${function2Test}:$(value controling) $(value var)"

  local controling=("differ" "${val}")
  local var1="$val"; echo var=$var1
  ${function2Test} controling "${var1}" ; report $? ${TEST_FAILING} "${function2Test}:$(value controling) $(value var1)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart control "_WithoutControledElement" && __test__() {

  function ownControler { return $1 ; }
  local controling=(ownControler 0)
  ${function2Test} controling ; report $? ${TEST_PASSING} "${function2Test}:$(value controling) $(value controled)"

  local controling=(ownControler 1)
  ${function2Test} controling ; report $? ${TEST_FAILING} "${function2Test}:$(value controling) $(value controled)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart arrayControl "_WithDummyControler" && __test__() {

  function arrayControlMatrix {
    declare -n arrayMatrix=$1
    declare -n controlerSet=$2
    declare -n resultMatrix=$3
    for (( i=0 ; i<${#controlerSet[@]} ; i++ )) ; do
      read -a controler <<< ${controlerSet[i]}
      read -a resultSet <<< ${resultMatrix[i]}
      for (( j=0 ; j<${#arrayMatrix[@]} ; j++ )) ; do
        read -a myArray <<< ${arrayMatrix[$j]}
        local expect=${resultSet[$j]}
        ${function2Test} myArray controler ; report $? ${expect} "${function2Test}:$(value myArray) $(value controler)"
      done
    done
  }

  unset aSet cSet cRes
  function f { [[ "$1" == "$2" ]] ; CR=$? ; : echo "controlValue:'$1' item:'$2' itemIndex:'$3' CR='$CR'" >&2 ; return $CR ; }
  local -a      cRes ; aSet=(  "a \"\""        )
  cSet+=('f "" n =') ; cRes+=("${TEST_FAILING}")
  cSet+=('f "" n !') ; cRes+=("${TEST_PASSING}")
  cSet+=('f "" 0 =') ; cRes+=("${TEST_PASSING}")
  cSet+=('f "" 0 !') ; cRes+=("${TEST_FAILING}")
  cSet+=('f "" 1 =') ; cRes+=("${TEST_FAILING}")
  cSet+=('f "" 1 !') ; cRes+=("${TEST_PASSING}")
  echo
  arrayControlMatrix aSet cSet cRes

  unset aSet cSet cRes
  function f { : echo "controlValue:$1 item:$2 itemIndex:$3" >&2 ; return $1 ; }
  local -a     cRes ; aSet=(  "a b"            ""              )
  cSet+=('f 0 n =') ; cRes+=("${TEST_PASSING}  ${TEST_FAILING}")
  cSet+=('f 0 n !') ; cRes+=("${TEST_FAILING}  ${TEST_PASSING}")
  cSet+=('f 0 0 =') ; cRes+=("${TEST_PASSING}  ${TEST_FAILING}")
  cSet+=('f 0 0 !') ; cRes+=("${TEST_FAILING}  ${TEST_PASSING}")
  cSet+=('f 0 1 =') ; cRes+=("${TEST_PASSING}  ${TEST_FAILING}")
  cSet+=('f 0 1 !') ; cRes+=("${TEST_FAILING}  ${TEST_PASSING}")
  cSet+=('f 1 n =') ; cRes+=("${TEST_FAILING}  ${TEST_FAILING}")
  cSet+=('f 1 n !') ; cRes+=("${TEST_PASSING}  ${TEST_PASSING}")
  cSet+=('f 1 0 =') ; cRes+=("${TEST_FAILING}  ${TEST_FAILING}")
  cSet+=('f 1 0 !') ; cRes+=("${TEST_PASSING}  ${TEST_PASSING}")
  cSet+=('f 1 1 =') ; cRes+=("${TEST_FAILING}  ${TEST_FAILING}")
  cSet+=('f 1 1 !') ; cRes+=("${TEST_PASSING}  ${TEST_PASSING}")
  echo
  arrayControlMatrix aSet cSet cRes

  unset aSet cSet cRes
  function f { return $2 ; }
  local -a     cRes ; aSet=(  ""              "1 0"           "0 1"           "1 1"           "0 0"           )
  cSet+=('f x n =') ; cRes+=("${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x n !') ; cRes+=("${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING}")
  cSet+=('f x 0 =') ; cRes+=("${TEST_FAILING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x 0 !') ; cRes+=("${TEST_PASSING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING} ${TEST_FAILING}")
  cSet+=('f x 1 =') ; cRes+=("${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x 1 !') ; cRes+=("${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING}")
  cSet+=('f x n =') ; cRes+=("${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x n !') ; cRes+=("${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING}")
  cSet+=('f x 0 =') ; cRes+=("${TEST_FAILING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x 0 !') ; cRes+=("${TEST_PASSING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING} ${TEST_FAILING}")
  cSet+=('f x 1 =') ; cRes+=("${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_FAILING} ${TEST_PASSING}")
  cSet+=('f x 1 !') ; cRes+=("${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_PASSING} ${TEST_FAILING}")
  echo
  arrayControlMatrix aSet cSet cRes

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart arrayControl "_WithControler" && __test__() {

  # all items are gt 10
  local array=(23 45 79 86 10)
  local controler=(gt 10 n =)
  ${function2Test} array controler ; report $? ${TEST_FAILING} "${function2Test}:$(value array) $(value controler)"

  # all items are non-integer
  local array=(aa bb cc dd ee)
  local controler=(isInteger "" n !)
  ${function2Test} array controler ; report $? ${TEST_PASSING} "${function2Test}:$(value array) $(value controler)"

  # one item is gt 80
  local array=(23 45 79 86 10)
  local controler=(gt 80 0 =)
  ${function2Test} array controler ; report $? ${TEST_PASSING} "${function2Test}:$(value array) $(value controler)"

  # no items should be gt 80
  local array=(23 45 79 86 10)
  local controler=(gt 80 0 !)
  ${function2Test} array controler ; report $? ${TEST_FAILING} "${function2Test}:$(value array) $(value controler)"

  # no items should be gt 80
  local array=(23 45 79 86 10)
  local controler=(le 80 1 =)
  ${function2Test} array controler ; report $? ${TEST_FAILING} "${function2Test}:$(value array) $(value controler)"

  # one item is gt 80
  local array=(23 45 79 86 10)
  local controler=(le 80 1 !)
  ${function2Test} array controler ; report $? ${TEST_PASSING} "${function2Test}:$(value array) $(value controler)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart match  && __test__() {

  local -a  e                       v                     p
            e+=(${TEST_PASSING})  ; v+=(999)            ; p+=('^[1-9][0-9]*$')
            e+=(${TEST_FAILING})  ; v+=(0999)           ; p+=('^[1-9][0-9]*$')
            e+=(${TEST_PASSING})  ; v+=("123 abcd 569") ; p+=('^[0-9]+[[:space:]]+[a-z]+[[:space:]]+[0-9]+$')
            e+=(${TEST_FAILING})  ; v+=("")             ; p+=('^[0-9]+$')
            e+=(${TEST_FAILING})  ; v+=(" ")            ; p+=('^[0-9]+$')
            e+=(${TEST_PASSING})  ; v+=(abcd)           ; p+=('')
            e+=(${TEST_FAILING})  ; v+=(abcd)           ; p+=(' ')

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local pattern=${p[i]}
    local value=${v[i]}
    local expect=${e[i]}
    ${function2Test} "${pattern}" "${value}" ; report $? ${expect} "${function2Test}:$(value pattern) $(value value)"
  done

  ${function2Test}                ; report $? ${TEST_PASSING} "${function2Test}:'' ''"
  ${function2Test} '' ''          ; report $? ${TEST_PASSING} "${function2Test}:'' ''"
  ${function2Test} $pU ${varU}    ; report $? ${TEST_PASSING} "${function2Test}:'' ''"


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart assert && __test__() {

  local -a  e                       a
            e+=(${TEST_FAILING})  ; a+=('W != W')
            e+=(${TEST_FAILING})  ; a+=('V == W')
            e+=(${TEST_PASSING})  ; a+=('W == W')
            e+=(${TEST_PASSING})  ; a+=('"W" == "W"')
            e+=(${TEST_PASSING})  ; a+=('V != W')
            e+=(${TEST_PASSING})  ; a+=(' ')
            e+=(${TEST_PASSING})  ; a+=('')

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local assertion=${a[i]}
    local expect=${e[i]}
    ${function2Test} "${assertion}"; report $? ${expect} "${function2Test}:$(value assertion)"
    local expect=${e[i]}
  done

  ${function2Test} ''         ; report $? ${TEST_PASSING} "${function2Test}:''"
  ${function2Test}            ; report $? ${TEST_PASSING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isInteger && __test__() {

  local -a  e                       v
            e+=(${TEST_PASSING})  ; v+=(9)
            e+=(${TEST_PASSING})  ; v+=(99)
            e+=(${TEST_PASSING})  ; v+=(999)
            e+=(${TEST_PASSING})  ; v+=(999999999999999999)
            e+=(${TEST_FAILING})  ; v+=(9999999999999999999)
            e+=(${TEST_FAILING})  ; v+=(0999)
            e+=(${TEST_FAILING})  ; v+=(abcd)
            e+=(${TEST_FAILING})  ; v+=(' ')
            e+=(${TEST_FAILING})  ; v+=('')
            e+=(${TEST_FAILING})  ; v+=('a b')

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value=${v[i]}
    local expect=${e[i]}
    ${function2Test} "${value}"; report $? ${expect} "${function2Test}:$(value value)"
    local expect=${e[i]}
  done

  ${function2Test} ''         ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}            ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isArray && __test__() {

  local var2=associativeEmptyArray
  declare -A "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=indexedEmptyArray
  declare -a "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=associativeNonEmptyArray
  declare -A "${var2}"
  eval ${var2}[a]=1
  eval ${var2}[b]=2
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=indexedNonEmptyArray
  declare -a "${var2}"
  eval ${var2}[0]=a
  eval ${var2}[1]=b
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  declare -A anArray
  local var2=referenceToArray
  declare -n ${var2}=anArray
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  declare aVariable
  local var2=referenceToVariable
  declare -n ${var2}=aVariable
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=unsetinedVariable
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=' '
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"
  ${function2Test} ''         ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}            ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isVariable && __test__() {

  # empty variables
  local var2=emptySimpleVariable
  declare ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyLowerCaseVariable
  declare -l ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyUpperCaseVariable
  declare -u ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyReadOnlyVariable
  readonly ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyGlobalVariable
  declare -g ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  declare aVariable
  local var2=referenceToEmptyVariable
  declare -n ${var2}=aVariable
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyIntegerVariable
  declare -i ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyTracedVariable
  declare -t ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyExportedVariable
  declare -x ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=emptyMultiAttributedVariable
  declare -xlt ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  # non empty variables
  local var2=nonEmptySimpleVariable
  declare ${var2}=a
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyLowerCaseVariable
  declare -l ${var2}=AAA
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyUpperCaseVariable
  declare -u ${var2}=aaa
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyReadOnlyVariable
  readonly ${var2}=a
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyGlobalVariable
  declare -g ${var2}=a
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  declare aVariable
  local var2=nonEmptyReferenceVariable
  declare -n ${var2}=aVariable
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyIntegerVariable
  declare -i ${var2}=2+2
  declare -p "${var2}"
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyTracedVariable
  declare -t ${var2}=a
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyExportedVariable
  declare -x ${var2}=a
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=nonEmptyMultiAttributedVariable
  declare -itx ${var2}=2+2
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  # errors
  local var2=unsetinedVariable
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=indexedArrray
  declare -a ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=associativeArrray
  declare -A "${var2}"
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=emptyMultiAttributedArray
  declare -xltA ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=referenceToUndefinedVariable
  declare -n ${var2}=WxZgDtfq
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=emptyReferenceVariable
  declare -n ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  declare -A anArray
  local var2=referenceToArray
  declare -n ${var2}=anArray
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=' '
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"
  ${function2Test} ''         ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}            ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isFunction && __test__() {

  f() { :; }
  local var2=f
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=g
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=' '
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  ${function2Test} ''       ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}          ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isEmpty && __test__() {

  local var2=' '
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:\"$(value var2)\""
  ${function2Test}  ${var2}   ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  ${function2Test} ''         ; report $? ${TEST_PASSING} "${function2Test}:''"
  ${function2Test}            ; report $? ${TEST_PASSING} "${function2Test}:"

  local var2=g
  ${function2Test} "${var2}"  ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isBlank && __test__() {

  local var2=' '
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:\"$(value var2)\""
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  ${function2Test} ''     ; report $? ${TEST_PASSING} "${function2Test}:''"
  ${function2Test}        ; report $? ${TEST_PASSING} "${function2Test}:"

  local var2=g
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isDefined && __test__() {

  local var2=definedVariable
  declare ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=definedArray
  declare -a ${var2}
  declare -p "${var2}"
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=referenceToDefinedVariable
  declare val
  declare -n ${var2}=val
  declare -p "${var2}"
  ${function2Test} "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var2)"

  local var2=unsetinedVariable
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=referenceToUndefinedVariable
  declare -n ${var2}=JmOICHGgfc
  declare -p "${var2}"
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=' '
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  local var2=''
  ${function2Test} "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var2)"

  ${function2Test} ''     ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}        ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart equal && __test__() {

  local val1='a b c'
  local val2='d e f'
  local val3=''
  local val4=' '
  local -a  e                       v1              v2
            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${TEST_FAILING})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${TEST_PASSING})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${TEST_PASSING})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${TEST_PASSING})  ; v1+=("$val4") ; v2+=("$val4")

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value1=${v1[i]}
    local value2=${v2[i]}
    local expect=${e[i]}
    ${function2Test} "${value1}" "${value2}" ; report $? ${expect} "${function2Test}:$(value value1) $(value value2)"
  done

  ${function2Test}                     ; report $? ${TEST_PASSING} "${function2Test}:"
  ${function2Test} ''                  ; report $? ${TEST_PASSING} "${function2Test}:''"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart differ && __test__() {

  local val1='a b c'
  local val2='d e f'
  local val3=''
  local val4=' '
  local -a  e                       v1              v2
            e+=(${TEST_PASSING})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${TEST_PASSING})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${TEST_PASSING})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${TEST_PASSING})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${TEST_PASSING})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${TEST_PASSING})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val4")

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value1=${v1[i]}
    local value2=${v2[i]}
    local expect=${e[i]}
    ${function2Test} "${value1}" "${value2}" ; report $? ${expect} "${function2Test}:$(value value1) $(value value2)"
  done

  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart after && __test__() {

  local val1='a b c'
  local val2='d e f'
  local val3=''
  local val4=' '
  local -a  e                       v1              v2
            e+=(${TEST_PASSING})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${TEST_FAILING})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${TEST_PASSING})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${TEST_PASSING})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val4")

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value1=${v1[i]}
    local value2=${v2[i]}
    local expect=${e[i]}
    ${function2Test} "${value1}" "${value2}" ; report $? ${expect} "${function2Test}:$(value value1) $(value value2)"
  done

  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart before && __test__() {

  local val1='a b c'
  local val2='d e f'
  local val3=''
  local -a  e                       v1              v2
            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${TEST_PASSING})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${TEST_PASSING})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${TEST_FAILING})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${TEST_FAILING})  ; v1+=("$val4") ; v2+=("$val4")

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value1=${v1[i]}
    local value2=${v2[i]}
    local expect=${e[i]}
    ${function2Test} "${value1}" "${value2}" ; report $? ${expect} "${function2Test}:$(value value1) $(value value2)"
  done

  v1='a b c'
  v2='d e f'

  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart eq  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart ne  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart lt  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart le  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart gt  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart ge  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1              v2
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${TEST_PASSING})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart inRange  && __test__() {

  local i__9=9
  local i_99=99
  local i999=999
  local i___=''
  local iABC=abc
  local -a  e                       v1                    v2
            e+=(${TEST_PASSING})  ; v1+=("$i__9 $i999") ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i__9 $i_99") ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i__9 $i_99") ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i_99")       ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i_99")       ; v2+=("$i999")
            e+=(${TEST_FAILING})  ; v1+=("$i_99")       ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___")       ; v2+=("$i___")
            e+=(${TEST_FAILING})  ; v1+=("$i___")       ; v2+=("$i_99")
            e+=(${TEST_FAILING})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2

  local var1="$i__9 $i_99"
  ${function2Test} "${var1}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value var1)"
  ${function2Test} "${i_99}"           ; report $? ${TEST_FAILING} "${function2Test}:$(value i_99)"
  ${function2Test} ''                  ; report $? ${TEST_FAILING} "${function2Test}:''"
  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart inArray  && __test__() {

  i9=9
  i99=99
  i999=999

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=$i9
  ${function2Test} var1 "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=$i99
  ${function2Test} var1 "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=$i999
  ${function2Test} var1 "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=''
  ${function2Test} var1 "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

  local var1=(a bc de "" f gh)
  local var2=''
  ${function2Test} var1 "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  unset var1
  local var1=''
  local var2=$i9
  ${function2Test} var1 "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

  local var1=''
  local var2=''
  ${function2Test} var1 "${var2}" ; report $? ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart not  && __test__() {

  local var1=assert
  local var2="W != W"
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=assert
  local var2="V == W"
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1="match ^[1-9][0-9]*$"
  local var2=0999
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1="match ^[0-9]+[[:space:]]+[a-z]+[[:space:]]+[0-9]+$"
  local var2="123 234 569"
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1="match ^[0-9]+$"
  local var2=""
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1="match ^[0-9]+$"
  local var2=" "
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  local var2=9999999999999999999
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  local var2=0999
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  local var2=abcd
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  local var2=' '
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  local var2=''
  ${function2Test} "${var1}" "${var2}" ; report $? ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var1=isInteger
  ${function2Test} "${var1}"           ; report $? ${TEST_PASSING} "${function2Test}:$(value var1)"

  ${function2Test}                     ; report $? ${TEST_FAILING} "${function2Test}:"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart !  && __test__() {

  local var1=0999
  ! isInteger "${var1}" ; report $? ${TEST_PASSING} "${function2Test}:$(value "! isInteger") $(value var1)"

  local var1="W != W"
  ! assert "${var1}"  ; report $? ${TEST_PASSING} "${function2Test}:$(value "! assert") $(value var1)"

  var0="! assert"
  local var1="W != W"
  eval "${var0} \"${var1}\""  ; report $? ${TEST_PASSING} "${function2Test}:$(value var0) $(value var1)"


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart matchArray  && __test__() {

  local var1=(1 100 abd 3 def 5 234)
  local var2='^[0-9]+$'
  i=$(${function2Test} var1 "${var2}") ; s=$? ; report $s ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"
  (( $s == 0 )) && echo "var1[$i]=${var1[$i]}"

  local var1=(1 100 abd 3 def 5 234)
  local var2='^[a-z]+$'
  i=$(${function2Test} var1 "${var2}") ; s=$? ; report $s ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"
  (( $s == 0 )) && echo "var1[$i]=${var1[$i]}"

  unset var1
  declare -A var1
  var1[aa]=1
  var1[bb]=100
  var1[00]=abd
  var1[cc]=3
  var1[01]=def
  var1[dd]=5
  var1[ee]=234
  local var2="^[0-9]+$"
  ${function2Test} var1 "${var2}" ; s=$? ; report $s ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  local var2="^[a-z]+$"
  ${function2Test} var1 "${var2}" ; s=$? ; report $s ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  unset var1
  local var1=(1 100 abc 3 5 def 234)
  local var2=""
  ${function2Test} var1 "${var2}" ; s=$? ; report $s ${TEST_PASSING} "${function2Test}:$(value var1) $(value var2)"

  unset var1
  local var1=""
  local var2="^[a-z]+$"
  ${function2Test} var1 "${var2}" ; s=$? ; report $s ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

  local var1=""
  local var2=""
  ${function2Test} var1 "${var2}" ; s=$? ; report $s ${TEST_FAILING} "${function2Test}:$(value var1) $(value var2)"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
