#-------------------------------------------------------------------------------
# core utility set

#-------------------------------------------------------------------------------
# import
declare  _CORELIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${helpLib+x} ]]   && source ${_CORELIB_LIB_PATH}/helpLib.sh
[[ -z ${logLib+x} ]]    && source ${_CORELIB_LIB_PATH}/logLib.sh
[[ -z ${traceLib+x} ]]  && source ${_CORELIB_LIB_PATH}/traceLib.sh
[[ -z ${ensureLib+x} ]] && source ${_CORELIB_LIB_PATH}/ensureLib.sh
unset  _CORELIB_LIB_PATH

#-------------------------------------------------------------------------------
# private variables
readonly _CORELIB_EXEC_NOPATH=${0##*/}

#-------------------------------------------------------------------------------
# public variables
declare -xr EXEC_NAME=${_CORELIB_EXEC_NOPATH%.*}
