#-------------------------------------------------------------------------------
# control enforcement utilities
[[ -z ${ensureLib} ]] || \
  echo 'warning ensureLib.sh sourced multiple times, protect import with [[ -z ${ensureLib+x} ]]' >&2
readonly ensureLib=1

#-------------------------------------------------------------------------------
# private section
#-------------------------------------------------------------------------------
declare _ENSURELIB_EXEC_NOPATH=${0##*/}
readonly _ENSURELIB_EXEC_NAME=${_ENSURELIB_EXEC_NOPATH%.*}
unset _ENSURELIB_EXEC_NOPATH

#-------------------------------------------------------------------------------
# public functions
function ensure        {
  eval ${@} || {
    echo "${_ENSURELIB_EXEC_NAME}:ENSURE:$@:FAILS:in ${FUNCNAME[1]}:file ${BASH_SOURCE[1]}:line ${BASH_LINENO[0]}" >&2
    kill -s TERM $$
  }
}
function disableEnsure {
  shopt -s expand_aliases
  alias ensure=":"
}
function enableEnsure  {
  unalias ensure
  shopt -u expand_aliases
}
