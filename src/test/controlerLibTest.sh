#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
#testingLib_WithTrace=true
controlerLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper
#import library under testing
[ -z ${controlerLib+x} ]  && source ${LIB_PATH}/controlerLib

#-------------------------------------------------------------------------------
# list of function to test
: '
controlF
control
control WithoutControledElement
arrayControl WithDummyControler
arrayControl WithControler
match
assert
isInteger
isArray
isVariable
isFunction
isEmpty
isBlank
isDefined
equal
differ
after
before
eq
ne
lt
le
gt
ge
inRange
inArray
not
!
matchArray
'
#-------------------------------------------------------------------------------
# tests utilities
#-------------------------------------------------------------------------------
function controlMatrix {
  local -n expectMatrix=$1
  local -n value1Matrix=$2
  local -n value2Matrix=$3
  for (( i=0 ; i<${#expectMatrix[@]}; i++ )) ; do
    local expect=${expectMatrix[i]}
    local value1=${value1Matrix[i]}
    local value2=${value2Matrix[i]}
    controled=(${function2Test} "${value1}" "${value2}")
    controlFunctionRC "${expect}" controled
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
  controled=(${function2Test} controling f "${var}")  ; controlFunctionRC ${EXPECT_PASS} controled

  local controling=(differ "${var}")
  controled=(${function2Test} controling f "${var}")  ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart control && __test__() {

  function f { echo $1 ; }
  local val=a

  local controling=("equal" "${val}")
  local controledX=("f" "${val}")
  controled=(${function2Test} controling controledX)  ; controlFunctionRC ${EXPECT_PASS} controled

  local controling=("differ" "${val}")
  local controledX=("f" "${val}" x y z)
  controled=(${function2Test} controling controledX)  ; controlFunctionRC ${EXPECT_FAIL} controled

  local controling=("differ" "${val}")
  local -n var=val
  controled=(${function2Test} controling var)  ; controlFunctionRC ${EXPECT_FAIL} controled

  local controling=("differ" "${val}")
  local var1="$val"; echo var=$var1
  controled=(${function2Test} controling "${var1}")  ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart control "_WithoutControledElement" && __test__() {

  function ownControler { return $1 ; }
  local controling=(ownControler 0)
  controled=(${function2Test} controling)  ; controlFunctionRC ${EXPECT_PASS} controled

  local controling=(ownControler 1)
  controled=(${function2Test} controling)  ; controlFunctionRC ${EXPECT_FAIL} controled

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
        controled=(${function2Test} myArray controler)  ; controlFunctionRC ${expect} controled
      done
    done
  }

  unset aSet cSet cRes
  function f { [[ "$1" == "$2" ]] ; CR=$? ; : echo "controlValue:'$1' item:'$2' itemIndex:'$3' CR='$CR'" >&2 ; return $CR ; }
  local -a      cRes ; aSet=(  "a \"\""        )
  cSet+=('f "" n =') ; cRes+=("${EXPECT_FAIL}")
  cSet+=('f "" n !') ; cRes+=("${EXPECT_PASS}")
  cSet+=('f "" 0 =') ; cRes+=("${EXPECT_PASS}")
  cSet+=('f "" 0 !') ; cRes+=("${EXPECT_FAIL}")
  cSet+=('f "" 1 =') ; cRes+=("${EXPECT_FAIL}")
  cSet+=('f "" 1 !') ; cRes+=("${EXPECT_PASS}")
  echo
  arrayControlMatrix aSet cSet cRes

  unset aSet cSet cRes
  function f { : echo "controlValue:$1 item:$2 itemIndex:$3" >&2 ; return $1 ; }
  local -a     cRes ; aSet=(  "a b"            ""              )
  cSet+=('f 0 n =') ; cRes+=("${EXPECT_PASS}  ${EXPECT_FAIL}")
  cSet+=('f 0 n !') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_PASS}")
  cSet+=('f 0 0 =') ; cRes+=("${EXPECT_PASS}  ${EXPECT_FAIL}")
  cSet+=('f 0 0 !') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_PASS}")
  cSet+=('f 0 1 =') ; cRes+=("${EXPECT_PASS}  ${EXPECT_FAIL}")
  cSet+=('f 0 1 !') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_PASS}")
  cSet+=('f 1 n =') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_FAIL}")
  cSet+=('f 1 n !') ; cRes+=("${EXPECT_PASS}  ${EXPECT_PASS}")
  cSet+=('f 1 0 =') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_FAIL}")
  cSet+=('f 1 0 !') ; cRes+=("${EXPECT_PASS}  ${EXPECT_PASS}")
  cSet+=('f 1 1 =') ; cRes+=("${EXPECT_FAIL}  ${EXPECT_FAIL}")
  cSet+=('f 1 1 !') ; cRes+=("${EXPECT_PASS}  ${EXPECT_PASS}")
  echo
  arrayControlMatrix aSet cSet cRes

  unset aSet cSet cRes
  function f { return $2 ; }
  local -a     cRes ; aSet=(  ""              "1 0"           "0 1"           "1 1"           "0 0"           )
  cSet+=('f x n =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x n !') ; cRes+=("${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL}")
  cSet+=('f x 0 =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x 0 !') ; cRes+=("${EXPECT_PASS} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS} ${EXPECT_FAIL}")
  cSet+=('f x 1 =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x 1 !') ; cRes+=("${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL}")
  cSet+=('f x n =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x n !') ; cRes+=("${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL}")
  cSet+=('f x 0 =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x 0 !') ; cRes+=("${EXPECT_PASS} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS} ${EXPECT_FAIL}")
  cSet+=('f x 1 =') ; cRes+=("${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_FAIL} ${EXPECT_PASS}")
  cSet+=('f x 1 !') ; cRes+=("${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_PASS} ${EXPECT_FAIL}")
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
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_FAIL} controled

  # all items are non-integer
  local array=(aa bb cc dd ee)
  local controler=(isInteger "" n !)
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_PASS} controled

  # one item is gt 80
  local array=(23 45 79 86 10)
  local controler=(gt 80 0 =)
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_PASS} controled

  # no items should be gt 80
  local array=(23 45 79 86 10)
  local controler=(gt 80 0 !)
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_FAIL} controled

  # no items should be gt 80
  local array=(23 45 79 86 10)
  local controler=(le 80 1 =)
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_FAIL} controled

  # one item is gt 80
  local array=(23 45 79 86 10)
  local controler=(le 80 1 !)
  controled=(${function2Test} array controler)  ; controlFunctionRC ${EXPECT_PASS} controled
 
} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart match  && __test__() {

  local -a  e                       v                     p
            e+=(${EXPECT_PASS})  ; v+=(999)            ; p+=('^[1-9][0-9]*$')
            e+=(${EXPECT_FAIL})  ; v+=(0999)           ; p+=('^[1-9][0-9]*$')
            e+=(${EXPECT_PASS})  ; v+=("123 abcd 569") ; p+=('^[0-9]+[[:space:]]+[a-z]+[[:space:]]+[0-9]+$')
            e+=(${EXPECT_FAIL})  ; v+=("")             ; p+=('^[0-9]+$')
            e+=(${EXPECT_FAIL})  ; v+=(" ")            ; p+=('^[0-9]+$')
            e+=(${EXPECT_PASS})  ; v+=(abcd)           ; p+=('')
            e+=(${EXPECT_FAIL})  ; v+=(abcd)           ; p+=(' ')

  controlMatrix e p v
  controled=(${function2Test})             ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test} '' '')       ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test} $pU ${varU}) ; controlFunctionRC ${EXPECT_PASS} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart assert && __test__() {

  local -a  e                       a
            e+=(${EXPECT_FAIL})  ; a+=('W != W')
            e+=(${EXPECT_FAIL})  ; a+=('V == W')
            e+=(${EXPECT_PASS})  ; a+=('W == W')
            e+=(${EXPECT_PASS})  ; a+=('"W" == "W"')
            e+=(${EXPECT_PASS})  ; a+=('V != W')
            e+=(${EXPECT_PASS})  ; a+=(' ')
            e+=(${EXPECT_PASS})  ; a+=('')

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local assertion=${a[i]}
    local expect=${e[i]}
    controled=(${function2Test} "${assertion}") ; controlFunctionRC ${expect} controled
  done

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_PASS} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isInteger && __test__() {

  local -a  e                       v
            e+=(${EXPECT_PASS})  ; v+=(9)
            e+=(${EXPECT_PASS})  ; v+=(99)
            e+=(${EXPECT_PASS})  ; v+=(999)
            e+=(${EXPECT_PASS})  ; v+=(999999999999999999)
            e+=(${EXPECT_FAIL})  ; v+=(9999999999999999999)
            e+=(${EXPECT_FAIL})  ; v+=(0999)
            e+=(${EXPECT_FAIL})  ; v+=(abcd)
            e+=(${EXPECT_FAIL})  ; v+=(' ')
            e+=(${EXPECT_FAIL})  ; v+=('')
            e+=(${EXPECT_FAIL})  ; v+=('a b')

  for (( i=0 ; i<${#e[@]}; i++ )) ; do
    local value=${v[i]}
    local expect=${e[i]}
    controled=(${function2Test} "${value}")   ; controlFunctionRC ${expect} controled
  done

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isArray && __test__() {

  local var2=associativeEmptyArray
  declare -A "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=indexedEmptyArray
  declare -a "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=associativeNonEmptyArray
  declare -A "${var2}"
  eval ${var2}[a]=1
  eval ${var2}[b]=2
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=indexedNonEmptyArray
  declare -a "${var2}"
  eval ${var2}[0]=a
  eval ${var2}[1]=b
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  declare -A anArray
  local var2=referenceToArray
  declare -n ${var2}=anArray
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  declare aVariable
  local var2=referenceToVariable
  declare -n ${var2}=aVariable
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2 #unsetVariable
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled
 
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isVariable && __test__() {

  # empty variables
  local var2=emptySimpleVariable
  declare ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyLowerCaseVariable
  declare -l ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyUpperCaseVariable
  declare -u ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyReadOnlyVariable
  readonly ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyGlobalVariable
  declare -g ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  declare aVariable
  local var2=referenceToEmptyVariable
  declare -n ${var2}=aVariable
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyIntegerVariable
  declare -i ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyTracedVariable
  declare -t ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyExportedVariable
  declare -x ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=emptyMultiAttributedVariable
  declare -xlt ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  # non empty variables
  local var2=nonEmptySimpleVariable
  declare ${var2}=a
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyLowerCaseVariable
  declare -l ${var2}=AAA
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyUpperCaseVariable
  declare -u ${var2}=aaa
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyReadOnlyVariable
  readonly ${var2}=a
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyGlobalVariable
  declare -g ${var2}=a
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  declare aVariable=x
  local var2=nonEmptyReferenceVariable
  declare -n ${var2}=aVariable
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyIntegerVariable
  declare -i ${var2}=2+2
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyTracedVariable
  declare -t ${var2}=a
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyExportedVariable
  declare -x ${var2}=a
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=nonEmptyMultiAttributedVariable
  declare -itx ${var2}=2+2
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  # errors
  local var2=unsetinedVariable
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=indexedArrray
  declare -a ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=associativeArrray
  declare -A "${var2}"
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=emptyMultiAttributedArray
  declare -xltA ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=referenceToUndefinedVariable
  declare -n ${var2}=WxZgDtfq
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=emptyReferenceVariable
  declare -n ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  declare -A anArray
  local var2=referenceToArray
  declare -n ${var2}=anArray
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isFunction && __test__() {

  f() { :; }
  local var2=f
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=g
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isEmpty && __test__() {

  local var2=g
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} ${var2})        ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_PASS} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isBlank && __test__() {

  local var2=g
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} ${var2})        ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_PASS} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart isDefined && __test__() {

  local var2=definedVariable
  declare ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=definedArray
  declare -a ${var2}
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=referenceToDefinedVariable
  declare val
  declare -n ${var2}=val
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_PASS} controled

  local var2=unsetVariable
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=referenceToUndefinedVariable
  declare -n ${var2}=JmOICHGgfc
  declare -p "${var2}"
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=' '
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  local var2=''
  controled=(${function2Test} "${var2}")      ; controlFunctionRC ${EXPECT_FAIL} controled

  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${EXPECT_FAIL})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${EXPECT_PASS})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${EXPECT_PASS})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${EXPECT_FAIL})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${EXPECT_PASS})  ; v1+=("$val4") ; v2+=("$val4")

  controlMatrix e v1 v2
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_PASS} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_PASS} controled

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
            e+=(${EXPECT_PASS})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${EXPECT_PASS})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${EXPECT_PASS})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${EXPECT_PASS})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${EXPECT_PASS})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${EXPECT_PASS})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${EXPECT_FAIL})  ; v1+=("$val4") ; v2+=("$val4")

  controlMatrix e v1 v2
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_PASS})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${EXPECT_FAIL})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${EXPECT_PASS})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${EXPECT_PASS})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${EXPECT_FAIL})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${EXPECT_FAIL})  ; v1+=("$val4") ; v2+=("$val4")
  
  controlMatrix e v1 v2
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart before && __test__() {

  local val1='a b c'
  local val2='d e f'
  local val3=''
  local val4=' '
  local -a  e                       v1              v2
            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val2")
            e+=(${EXPECT_PASS})  ; v1+=("$val2") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val1") ; v2+=("$val1")

            e+=(${EXPECT_PASS})  ; v1+=("$val1") ; v2+=("$val3")
            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val1")
            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val3")

            e+=(${EXPECT_FAIL})  ; v1+=("$val3") ; v2+=("$val4")
            e+=(${EXPECT_PASS})  ; v1+=("$val4") ; v2+=("$val3")
            e+=(${EXPECT_FAIL})  ; v1+=("$val4") ; v2+=("$val4")

  controlMatrix e v1 v2
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i__9")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i_99")
            e+=(${EXPECT_PASS})  ; v1+=("$i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '')             ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled


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
            e+=(${EXPECT_PASS})  ; v1+=("$i__9 $i999") ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i__9 $i_99") ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i__9 $i_99") ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99")       ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99")       ; v2+=("$i999")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99")       ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___")       ; v2+=("$i___")
            e+=(${EXPECT_FAIL})  ; v1+=("$i___")       ; v2+=("$i_99")
            e+=(${EXPECT_FAIL})  ; v1+=("$i_99") ; v2+=("$iABC")

  controlMatrix e v1 v2

  local var1="$i__9 $i_99"
  controled=(${function2Test} "${var1}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} "${i_99}")      ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test} '' '')          ; controlFunctionRC ${EXPECT_FAIL} controled
  controled=(${function2Test})                ; controlFunctionRC ${EXPECT_FAIL} controled

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
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=$i99
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=$i999
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

  local var1=(1 100 $i9 $i99 3 5 234)
  local var2=''
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

  local var1=(a bc de "" f gh)
  local var2=''
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  unset var1
  local var1=''
  local var2=$i9
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

  local var1=''
  local var2=''
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart not  && __test__() {

  local var1=assert
  local var2="W != W"
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=assert
  local var2="V == W"
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1="match ^[1-9][0-9]*$"
  local var2=0999
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1="match ^[0-9]+[[:space:]]+[a-z]+[[:space:]]+[0-9]+$"
  local var2="123 234 569"
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1="match ^[0-9]+$"
  local var2=""
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1="match ^[0-9]+$"
  local var2=" "
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  local var2=9999999999999999999
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  local var2=0999
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  local var2=abcd
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  local var2=' '
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  local var2=''
  controled=(${function2Test} "${var1}" "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=isInteger
  controled=(${function2Test} "${var1}")
  controlFunctionRC ${EXPECT_PASS} controled

  controled=(${function2Test})
  controlFunctionRC ${EXPECT_FAIL} controled


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart !  && __test__() {

  local var1=0999
  ! isInteger "${var1}"
  reportFunctionRC $? ${EXPECT_PASS} "${function2Test}" isInteger "${var1}"


  local var1="W != W"
  ! assert "${var1}"
  reportFunctionRC $? ${EXPECT_PASS} "${function2Test}" assert "${var1}"

  var0="! assert"
  local var1="W != W"
  reportFunctionRC $? ${EXPECT_PASS} "${function2Test}" eval "${var0} \"${var1}\""


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart matchArray  && __test__() {

  local var1=(1 100 abd 3 def 5 234)
  local var2='^[0-9]+$'
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var1=(1 100 abd 3 def 5 234)
  local var2='^[a-z]+$'
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

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
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  local var2="^[a-z]+$"
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  unset var1
  local var1=(1 100 abc 3 5 def 234)
  local var2=""
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_PASS} controled

  unset var1
  local var1=""
  local var2="^[a-z]+$"
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

  local var1=""
  local var2=""
  controled=(${function2Test} var1 "${var2}")
  controlFunctionRC ${EXPECT_FAIL} controled

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
