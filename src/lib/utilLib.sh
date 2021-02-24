#-------------------------------------------------------------------------------
# misc utilities
[[ -z ${utilLib} ]] || \
  (echo 'warning utilLib.sh sourced multiple times, protect import with [[ -z ${utilLib+x} ]]' >&2)
readonly utilLib=1

#-------------------------------------------------------------------------------
# public functions
function checkFileAccess () {
  fullFileName=$1
  # check if the file is a regular file
  if [[ ! -f ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: do not exist or not a regular file"
    return 1
  fi

  # check if the file can be read
  if [[ ! -r ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: unable to read"
    return 1
  fi

  # check if the file can be writen
  if [[ ! -w ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: unable to write"
    return 1
  fi
  return 0
}
