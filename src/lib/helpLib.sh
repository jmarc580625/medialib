#-------------------------------------------------------------------------------
# usage & help utilities
[[ -z ${helpLib} ]] || \
  (echo 'warning helpLib sourced multiple times, protect import with [[ -z ${helpLib+x} ]]' >&2)
readonly helpLib=1

#-------------------------------------------------------------------------------
# public functions
function usage () { (printf "${USAGE}\n" ${EXEC_NAME} >&2) ; }
#function help ()  { usage ; echo "${HELP}" >&2 ; }
function help ()  { usage ; eval "printf %s\\n \"${HELP}\" >&2" ; }
