#-------------------------------------------------------------------------------
# trap control utilities
[[ -z ${trapLib} ]] || \
  echo 'warning trapLib sourced multiple times, protect import with [[ -z ${trapLib+x} ]]' >&2
readonly trapLib=1

#-------------------------------------------------------------------------------
# private section
# credit to https://stackoverflow.com/users/1449569/iron-savior
# adapted from https://stackoverflow.com/questions/16115144/save-and-restore-trap-state-easy-way-to-manage-multiple-handlers-for-traps
function _trapStackName      { local sig=${1//[^a-zA-Z0-9]/_} ; echo "__trapStack${sig}" ; }
function _trapExtractHandler { echo "${@:3:$(($#-3))}" ; }
function _trapPush           {
  local -n __stack__=$1
  __stack__[${#__stack__[@]}]=$2
  trap "$3" "$4"
}

#-------------------------------------------------------------------------------
# public section
# credit to https://stackoverflow.com/users/1449569/iron-savior
# adapted from https://stackoverflow.com/questions/16115144/save-and-restore-trap-state-easy-way-to-manage-multiple-handlers-for-traps
function trapGetHandler  {
  if t=$(trap -p $1 2>&-) ; then
    eval echo $(_trapExtractHandler $t)
    return 0
  else
    return 64
  fi
}
function trapPush        {
  local newTrap=$1
  shift
  for sig in "$@" ; do
    if oldTrap=$(trapGetHandler "${sig}") ; then
      _trapPush "$(_trapStackName "${sig}")" "${oldTrap}" "${newTrap}" "${sig}"
    fi
  done
}
function trapPop         {
  for sig in "$@" ; do
    if oldTrap=$(trapGetHandler "${sig}") ; then
      local -n stack=$(_trapStackName "${sig}")
      local count=${#stack[@]}
      (( $count < 1 )) && continue
      (( count-- ))
      local newTrap=${stack[${count}]}
      trap "${newTrap}" "${sig}"
      unset stack["${count}"]
    fi
  done
}
function trapPrepend     {
  local handler=$1
  shift
  for sig in "$@" ; do
    if oldTrap=$(trapGetHandler "${sig}") ; then
      newTrap=$([[ -n "${oldTrap}" ]] &&  echo "${handler} ; ${oldTrap}" || echo "${handler}")
      _trapPush "$(_trapStackName "${sig}")" "${oldTrap}" "${newTrap}" "${sig}"
    fi
  done
}
function trapAppend      {
  local handler=$1
  shift
  for sig in "$@" ; do
    if oldTrap=$(trapGetHandler "${sig}") ; then
      newTrap=$([[ -n "${oldTrap}" ]] &&  echo "${oldTrap} ; ${handler}" || echo "${handler}")
      _trapPush "$(_trapStackName "${sig}")" "${oldTrap}" "${newTrap}" "${sig}"
    fi
  done
}
