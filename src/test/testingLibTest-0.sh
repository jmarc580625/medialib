#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
TESTDRIVER_HOME=${0%/*}
LIB_PATH=$(realpath ${TESTDRIVER_HOME}/../../lib)
# import test driver helper
testingLib_WithTrace=true
[ -z ${testingHelper+x} ]  && source ${LIB_PATH}/testingHelper

#-------------------------------------------------------------------------------
# list of function to test
: '
'

#-------------------------------------------------------------------------------
declare fnCnt=0
declare valCnt=0

#-------------------------------------------------------------------------------
# tests
# test suite initialisation
suiteStart testingLib_CoreFunctions "test utilities"

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart displayElement "_WithoutParameter" && __test__() {

    ${function2Test}

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart displayElement "_WithMultipleParameter" && __test__() {

    ${function2Test} abc def ghi

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart displayElement "_WithValue" && __test__() {

  local simpleTextValue="abc"
  ${function2Test} "${simpleTextValue}"

  local simpleNumericValue="999"
  ${function2Test} "${simpleNumericValue}"

  local valueWithSpace="hello happy taxpayer"
  ${function2Test} "${valueWithSpace}"

  local blankValue="  "
  ${function2Test} "${blankValue}"

  local emptyValue=""
  ${function2Test} "${emptyValue}"

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart displayElement "_WithVariable" && __test__() {

  local simpleVariable="abc"
  ${function2Test} simpleVariable

  local variableWithSpace="hello happy taxpayer"
  ${function2Test} variableWithSpace

  local blankVavariable="  "
  ${function2Test} blankVavariable

  local emptyVariable=""
  ${function2Test} emptyVariable

  unset undefinedVariable
  ${function2Test} undefinedVariable

  unset undefinedVariable
  declare -n referenceToUndefinedVariable=undefinedVariable
  ${function2Test} referenceToUndefinedVariable

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart displayElement "_WithArray" && __test__() {

  local -a indexedArray=(a b c d)
  ${function2Test} indexedArray

  local -a emptyIndexedArray
  ${function2Test} emptyIndexedArray

  local -A associativeArray
  associativeArray[a]=1
  associativeArray[b]=2
  associativeArray[c]=3
  ${function2Test} associativeArray

  local -A emptyAssociativeArray
  ${function2Test} emptyAssociativeArray

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithOwnControler" && __test__() {

  function OwnControler { [[ "$1" == "$2" ]] ; }
  local v1=ok
  local v2=ko
  local controling=(OwnControler "$v1")

  local controled=(echoDollar1 "$v1")
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 "$v2")
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithEqual" && __test__() {

  local v1='a b c'
  local v2='d e f'
  local v3='-qbt:x y'
  local controling=(equal "$v1")

  local controled=(echoDollar1 "$v1")
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 "$v2")
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 "$v3")
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithIsInteger" && __test__() {

  local controling=(isInteger)

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 'a b c')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithMatch" && __test__() {

  local controling=(match '^[0-9]+$')

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 'a b c')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithInRange" && __test__() {

  local controling=(inRange '1 100')

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 'a b c')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithInArray" && __test__() {

  local v1=(1 100 9 99 3 5 234)
  local controling=(inArray v1)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 '')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 '9 xx')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithEq" && __test__() {

  local controling=(eq 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithNe" && __test__() {

  local controling=(ne 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithLt" && __test__() {

  local controling=(lt 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithLe" && __test__() {

  local controling=(le 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithGt" && __test__() {

  local controling=(gt 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithGe" && __test__() {

  local controling=(ge 99)

  local controled=(echoDollar1 9)
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 99)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 999)
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlFunction "_WithAssert" && __test__() {

  local controling=(assert)

  local controled=(echoDollar1 '"V" == "V"')
  ${function2Test} "${EXPECT_PASS}" controling controled         ; (( fnCnt++ ))

  local controled=(echoDollar1 '"V" == "X"')
  ${function2Test} "${EXPECT_FAIL}" controling controled         ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithOwnControler" && __test__() {

  function OwnControler { [[ "$1" == "$2" ]] ; }
  local v1=ok
  local v2=ko
  local controling=(OwnControler "$v1")

  ${function2Test} "${EXPECT_PASS}" controling "$v1"             ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"             ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling v1                ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling v2                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithEqual" && __test__() {

  local v1='a b c'
  local v2='d e f'
  local controling=(equal "$v1")

  ${function2Test} "${EXPECT_PASS}" controling "$v1"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"              ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithIsInteger" && __test__() {

  local controling=(isInteger)
  local v1='999'
  local v2='a b c'

  ${function2Test} "${EXPECT_PASS}" controling "$v1"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"              ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithMatch" && __test__() {

  local controling=(match '^[0-9]+$')
  local v1='999'
  local v2='a b c'

  ${function2Test} "${EXPECT_PASS}" controling "$v1"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"              ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithInRange" && __test__() {

  local controling=(inRange '1 100')
  local v1='9'
  local v2='999'
  local v3='a b c'

  ${function2Test} "${EXPECT_PASS}" controling "$v1"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v3"              ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithInArray" && __test__() {

  local a1=(1 100 9 99 3 5 234)
  local controling=(inArray a1)
  local v1=9
  local v2=999
  local v3='a b c'

  ${function2Test} "${EXPECT_PASS}" controling "$v1"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v2"              ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling "$v3"              ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithEq" && __test__() {

  local controling=(eq 99)

  ${function2Test} "${EXPECT_FAIL}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithNe" && __test__() {

  local controling=(ne 99)

  ${function2Test} "${EXPECT_PASS}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithLt" && __test__() {

  local controling=(lt 99)

  ${function2Test} "${EXPECT_PASS}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithLe" && __test__() {

  local controling=(le 99)

  ${function2Test} "${EXPECT_PASS}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithGt" && __test__() {

  local controling=(gt 99)

  ${function2Test} "${EXPECT_FAIL}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_FAIL}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart controlValue "_WithGe" && __test__() {

  local controling=(ge 99)

  ${function2Test} "${EXPECT_FAIL}" controling 9                  ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 99                 ; ((valCnt++))
  ${function2Test} "${EXPECT_PASS}" controling 999                ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlight "_CheckIsOnOrOff" && __test__() {

  local controling=(match '^(on|off)$')
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlight "_CheckSettingOff" && __test__() {

  setHighlightOff
  local controling=(equal off)
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getHighlight "_CheckSettingOn" && __test__() {

  setHighlightOn
  local controling=(equal on)
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart formats "_CheckSupportedValues" && __test__() {

  read -a formats <<< $(getSupportedOutFormats)
  local controling=(match '^(Xml|Json|Txt)$')
  for f in ${formats[@]} ; do
    controlValue  "${EXPECT_PASS}" controling $f                  ; ((valCnt++))
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart formats "_SetAllSupportedValues" && __test__() {

  read -a formats <<< $(getSupportedOutFormats)
  for tempativeFormat in ${formats[@]} ; do
    setOutFormat $tempativeFormat   ; displayElement tempativeFormat
    local resultingFormat=$(getOutFormat) ; displayElement resultingFormat
    local controling=(equal "$tempativeFormat")
    controlValue  "${EXPECT_PASS}" controling "$resultingFormat"     ; ((valCnt++))
  done

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart formats "_SettingWrongValue" && __test__() {

  local currentFormat=$(getOutFormat)   ; displayElement currentFormat
  local tempativeFormat=FuBaz           ; displayElement tempativeFormat
  setOutFormat $tempativeFormat
  local resultingFormat=$(getOutFormat) ; displayElement resultingFormat

  local controling=(differ "$tempativeFormat")
  controlValue  "${EXPECT_PASS}" controling "$resultingFormat"    ; ((valCnt++))

  local controling=(equal "$currentFormat")
  controlValue  "${EXPECT_PASS}" controling "$resultingFormat"    ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart formats "_DefaultValue" && __test__() {

  setDefaultOutFormat
  read -a formats <<< $(getSupportedOutFormats)
  displayElement fmts
  local controling=(inArray formats)
  local controled=(getOutFormat)
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart testStatus && __test__() {

  displayElement TEST_STATUS
  local controling=(equal "")
  controlValue  "${EXPECT_PASS}" controling "${TEST_STATUS}"      ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getRandom && __test__() {

  local limit=1000
  local controling=(le "$limit")
  local controled=(${function2Test} "${limit}")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local limit=100
  local controling=(le "$limit")
  local controled=(${function2Test} "${limit}")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getRandom "_WithoutUpperLimit"  && __test__() {

  local limit=10
  local controling=(le "$limit")
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getRandom "_ConsecutiveInvocation" && __test__() {

  local limit=10
  local v1=$(getRandom ${limit})
  local v2=$(getRandom ${limit})
  local controling=(ne "$v1")
  controlValue "${EXPECT_PASS}" controling "$v2"                  ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollar1 "_WithSimpleText" && __test__() {

  local v1=abc
  local v2=def
  local controling=(equal "$v1")

  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollar1 "_WithNumber" && __test__() {

  local v1=123
  local v2=876
  local controling=(equal "$v1")

  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))


} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollar1 "_WithText" && __test__() {

  local v1="hello world"
  local v2="all folks"
  local controling=(equal "$v1")

  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollarAll "_WithSimpleText" && __test__() {

  local v1=abc
  local v2=def

  local controling=(equal "$v1")
  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controling=(equal "$v1 $v2")
  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollarAll "_WithNumber" && __test__() {

  local v1=123
  local v2=876

  local controling=(equal "$v1")
  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controling=(equal "$v1 $v2")
  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))


} && __test__ ; itemEnd

#-------v------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart echoDollarAll "_WithText" && __test__() {

  local v1="hello world"
  local v2="all folks"

  local controling=(equal "$v1")
  local controled=(${function2Test} "$v1")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

  local controling=(equal "$v1 $v2")
  local controled=(${function2Test} "$v1" "$v2")
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart satisticsItemCount && __test__() {

  local itmCnt=$(itemCountGet)

  local controling=(eq ${itmCnt})
  local controled=(${function2Test})
  controlFunction "${EXPECT_PASS}" controling controled          ; (( fnCnt++ ))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getSatisticsFunctionControl && __test__() {

  read fnPassed fnSucceded <<< "$(${function2Test})"

  local controling=(eq "${fnPassed}")
  controlValue "${EXPECT_PASS}" controling fnCnt                  ; ((valCnt++))
  echo fnCnt=$fnCnt
  echo valCnt=$valCnt

  local controling=(le "${fnPassed}")
  controlValue "${EXPECT_PASS}" controling fnSucceded             ; ((valCnt++))
  echo valCnt=$valCnt

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
#forceTest=true
#setTraceOn
itemStart getSatisticsVariableControl && __test__() {

  read valPassed valSucceded <<< "$(${function2Test})"

  local controling=(eq "${valPassed}")
  controlValue "${EXPECT_PASS}" controling valCnt                 ; ((valCnt++))

  local controling=(le "${valPassed}")
  controlValue "${EXPECT_PASS}" controling valSucceded            ; ((valCnt++))

} && __test__ ; itemEnd

#-------------------------------------------------------------------------------
suiteEnd
