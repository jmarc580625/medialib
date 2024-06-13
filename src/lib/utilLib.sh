#-------------------------------------------------------------------------------
# misc utilities
[[ -z ${utilLib} ]] || \
  (echo 'warning utilLib sourced multiple times, protect import with [[ -z ${utilLib+x} ]]' >&2)
readonly utilLib=1


#-------------------------------------------------------------------------------
# private functions
function _checkFileIsRegular () {
  local fileName=$*
  if [[ ! -f "${fileName}" ]] ; then  # check if the file is a regular file
    info "'${fileName}': ignore: do not exist or not a regular file"
    return 1
  fi
  return 0
}

function _checkWriteAccessFile () {
  local fileName=$*
  if [[ ! -w "${fileName}" ]] ; then   # check if the file can be writen
    info "'${fileName}': ignore: unable to write"
    return 1
  fi
  return 0
}

function _checkReadAccessFile () {
  local fileName=$*
  if [[ ! -r "${fileName}" ]] ; then  # check if the file can be read
    info "'${fileName}': ignore: unable to read"
    return 1
  fi
  return 0
}

#-------------------------------------------------------------------------------
# public functions
function checkFullAccessFile () {
  local fileName=$*
  _checkFileIsRegular "${fileName}" &&
  _checkReadAccessFile "${fileName}" &&
  _checkWriteAccessFile "${fileName}"
}

function checkReadAccessFile () {
  local fileName=$*
  _checkFileIsRegular "${fileName}" &&
  _checkReadAccessFile "${fileName}"
}

function checkWriteAccessFile () {
  local fileName=$*
  _checkFileIsRegular "${fileName}" &&
  _checkWriteAccessFile "${fileName}"
}

function checkIsRegularFile () {
  local fileName=$*
  _checkFileIsRegular "${fileName}"
}
