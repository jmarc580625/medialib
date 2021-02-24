#-------------------------------------------------------------------------------
# usage & help utilities
[[ -z ${helpLib} ]] || \
  (echo 'warning helpLib.sh sourced multiple times, protect import with [[ -z ${helpLib+x} ]]' >&2)
readonly helpLib=1

#-------------------------------------------------------------------------------
# public functions
function usage () { (printf "${USAGE}\n" ${EXEC_NAME} >&2) ; }
function help ()  { usage ; echo "${HELP}" >&2 ; }
