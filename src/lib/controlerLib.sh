#-------------------------------------------------------------------------------
# control utilities
[[ -z ${controlerLib} ]] || \
  (echo 'warning controlerLib.sh imported multiple times, protect import with [[ -z ${controlerLib+x} ]]' >&2)
readonly controlerLib=1

#-------------------------------------------------------------------------------
# import
declare _CONTROLERLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]]   && source ${_CONTROLERLIB_LIB_PATH}/traceLib
[[ -z ${ensureLib+x} ]] && source ${_CONTROLERLIB_LIB_PATH}/ensureLib
unset _CONTROLERLIB_LIB_PATH

[[ "${controlerLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions
[[ "${controlerLib_WithEnsure}" != "true" ]]  && disableEnsure # disabling ensureLib functions

#-------------------------------------------------------------------------------
# private section
readonly _isArrayRE='^declare[[:space:]]-[aA]'
readonly _isReferenceRE='^declare[[:space:]]-n'
readonly _isVariableRE='^declare[[:space:]]-[-itxrlu]+'
readonly _isFunctionRE='^function$'
readonly _isBlankRE='^[[:space:]]*$'

# if $1 is the name of a reference return the referenced variable name otherwise return the variable name
function _getVarSpec  {
  if varSpec=$(declare -p "$1" 2>&-) ; then
    if [[ "${varSpec}" =~ ${_referenceRE} ]] ; then
      local q1=${varSpec/#*=/}
      local varName=$(echo ${q1//\"/})
      if varSpec=$(declare -p "${varName}" 2>&-) ; then
        echo ${varSpec}
        return 0
      else
        echo
        return 1
      fi
    else
      echo ${varSpec}
      return 0
    fi
  else
    echo
    return 1
  fi
}
function _getRef      {
  d1=$(declare -p "$1" 2>&-)
  match "${_isReferenceRE}" "$d1" && { q1=${d1/#*=/} ; echo ${q1//\"/} ; } || echo $1
}
# testedValue=$1 ; controlValue=$2
function _comp   { eval [[ \"$1\" $2 \"$3\" ]] && return 0 || return 1 ; }
function _compN  { isInteger "$1" && isInteger "$3" && _comp "$@" ; }

#-------------------------------------------------------------------------------
# public section
readonly integerRE='^(0|[1-9][0-9]{0,17})$'

# controling function prototype
# testCriteria=$1 ; testedValue=$2 ; compareFunction=$3
function protoControler   {
  local testCriteria=$1 ; traceVar testCriteria
  local testedValue=$2  ; traceVar testedValue
  : "TEST HERE" && return 0 || return 1
}

# unary controler
#function assert      { eval "[[ \"${1:-$2}\" ]]" && return 0 || return 1 ; }
function assert      { v="${1:-$2}" ; ( isBlank "$v" || eval "[[ $v ]]" ) && return 0 || return 1 ; }
function isVariable  { local varSpec=$(_getVarSpec "${1:-$2}")     && match "${_isVariableRE}"  "${varSpec}" ; }
function isArray     { local varSpec=$(_getVarSpec "${1:-$2}")     && match "${_isArrayRE}"     "${varSpec}" ; }
function isReference { local varSpec=$(declare -p "${1:-$2}" 2>&-) && match "${_isReferenceRE}" "${varSpec}" ; }
function isFunction  { local type=$(type -t "${1:-$2}" 2>&-)       && match "${_isFunctionRE}"  "${type}" ; }
function isDefined   { _getVarSpec "${1:-$2}" ; }
function isEmpty     { [[ -z "${1:-$2}" ]] && return 0 || return 1 ; }
function isInteger   { match "${integerRE}"  "${1:-$2}" ; }
function isBlank     { match "${_isBlankRE}" "${1:-$2}" ; }

# binary controler
# testedValue=$2 ; controlValue=$1
function match   { [[ "$2" =~ $1 ]] && return 0 || return 1 ; }
function equal   { _comp  "${2//\"/\\\"}" "==" "${1//\"/\\\"}" ; }
function differ  { _comp  "${2//\"/\\\"}" "!=" "${1//\"/\\\"}" ; }
function after   { _comp  "${2//\"/\\\"}" ">"  "${1//\"/\\\"}" ; }
function before  { _comp  "${2//\"/\\\"}" "<"  "${1//\"/\\\"}" ; }
function eq      { (( "$2" == "$1" )) 2>&- ; }
function ne      { (( "$2" != "$1" )) 2>&- ; }
function gt      { (( "$2" >  "$1" )) 2>&- ; }
function ge      { (( "$2" >= "$1" )) 2>&- ; }
function lt      { (( "$2" <  "$1" )) 2>&- ; }
function le      { (( "$2" <= "$1" )) 2>&- ; }
function inRange {
  local testedValue=$2          ; traceVar testedValue
  read -r lowBound highBound <<< $1
  isInteger ${testedValue} && isInteger ${highBound} && isInteger ${lowBound} && \
  (( ${lowBound} <= ${testedValue} && ${testedValue} <= ${highBound} )) && return 0 || return 1
}
function not     {
  if isFunction $1 ; then
    controler=($1)
    call="${controler[0]}"
    (( ${#controler[@]} > 1 )) && call="${call} \"${controler[1]}\""
    call="${call} \"$2\""
    eval ${call} && return 1 || return 0
  else
    return 128
  fi
}
function inArray    { local controler=(equal "$2" 0 =) ; arrayControl "$1" controler ; }
function matchArray { local controler=(match "$2" 0 =) ; arrayControl "$1" controler ; }
# $1 array to control
# $2 array controler with
#    $2[0] control function name
#    $2[1] controled value
#    $2[2] control flow :
#       - 0 stop on first control function success
#       - 1 stop on first control function failure
#       - n (or any other string) iterate over the whole array
#    $2[3] control reported result
#       - if the array is empty or if any test has failed the function report an error
#       - unless ! is used as a result controler to revert function result
function arrayControl   {
  if ! isArray $1 ; then return 1 ; fi
  if ! isArray $2 ; then return 1 ; fi
  local -n __array=$1        ; traceVar __array
  declare -n controlArray=$2
  local controlFunction=${controlArray[0]}  ; traceVar controlFunction
  local controlValue=${controlArray[1]}     ; traceVar controlValue
  local controlFlow=${controlArray[2]}      ; traceVar controlFlow
  local controlResult=${controlArray[3]}    ; traceVar controlResult
  functionRC=1
  callNumber=0
  hasFailed=0
  for k in "${!__array[@]}" ; do
    eval ${controlFunction} \"${controlValue}\" \"${__array[$k]}\" \"$k\"
    functionRC=$( [[ "$?" == 0 ]] && echo 0 || echo 1 )
    (( callNumber++ ))
    (( hasFailed += functionRC ))
    if [[ "${functionRC}" == "${controlFlow}" ]] ; then
#      setTraceOn; trace interupted; trace $(declare -p "$1"); traceVar controlValue; traceVar functionRC; traceVar controlFlow; setTraceOff
      return $(_controlResult "${controlResult}" "${functionRC}")
    fi
  done
  (( functionRC += hasFailed ))
#  setTraceOn; trace fullscan; trace $(declare -p "$1"); traceVar controlValue; traceVar functionRC; traceVar controlFlow; setTraceOff
  return $(_controlResult "${controlResult}" "${functionRC}")
}
function _controlResult { if [[ "$1" == "!" ]] ; then [[ ! $2 == 0 ]] ; else [[ $2 == 0 ]] ; fi ; echo $? ; }
function _formatList    { out1=("$@"); out2=$(IFS=, ; echo "${out1[*]}") ; echo "('${out2//,/\',\ \'}')" ; }
# $1 controler is a vector containing
#     [0] control function or controler reference for nested control
#     [1] control criteria
# $@:2 function to control ans its parameters
function controlF       { toTest=(${@:2}) ; control $1 toTest ; }
function control        {
  trace "params=$@"
  ensure isArray "$1"

  local valueToControl=""
  local valueDisplay=""

  if isArray "$2" ; then
    local -n functionArray=$2
    params=("${functionArray[@]:1}") ; traceVar params
    local toTest=${functionArray[0]}   ; traceVar toTest
    ensure isFunction "${toTest}"
    valueToControl=$(${toTest} "${params[@]}") ; traceVar valueToControl
    valueDisplay="\"${toTest}$(_formatList "${params[@]}")=>${valueToControl}\""
  elif isVariable $2 ; then
    declare -n variableRef=$2
    valueToControl=${variableRef}
    valueDisplay="\"${2}=>${valueToControl}\""
  elif isBlank $2 ; then
    valueToControl=""
    valueDisplay="\"\""
  else
    valueToControl=$2
    valueDisplay="\"${valueToControl}\""
  fi

  declare -n controlArray=$1
  local criteria=${controlArray[1]}   ; traceVar criteria
  local controler=${controlArray[0]}  ; traceVar controler
  ensure isFunction "${controler}"
  ${controler} "${criteria}" "${valueToControl}"
  local controlResult=$? ; traceVar controlResult
  local controlDisplay="\"${controler}$(_formatList "${criteria}" "${valueToControl}")=>${controlResult}\""

  echo "${controlDisplay} ${valueDisplay}"
  return ${controlResult}
}

[[ "${controlerLib_WithTrace}" != "true" ]]   && enableTrace
[[ "${controlerLib_WithEnsure}" != "true" ]]  && enableEnsure
