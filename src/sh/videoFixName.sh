#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
# get script location
EXEC_HOME=${0%/*}
LIB_DIR=$(realpath ${EXEC_HOME}/../lib)
source ${LIB_DIR}/coreLib
#-------------------------------------------------------------------------------
# usage & help
#-------------------------------------------------------------------------------
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] (-u | ((-r | -w) "<who> <what> <where>")) <source files>'
readonly HELP="
Rename video files according to the following pattern: <who>-<what>@<where>[<duration>,<size>(,G)?].<ext>
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -u: update <duration> and <size> according to video characteristics
      no renaming is performed if the filename does not follow the pattern
  -r: replace existing <who> <what> <where> elements in the naming pattern
      <duration> and <size> are updated according to video characteristics
      no renaming is performed if the filename does not follow the pattern
  -w: rename the file according to the pattern
      <who> <what> <where> must be character strings separated by blanks surounded by quotes
      <duration> and <size> are set according to video characteristics
      no renaming is performed if the filename follows the pattern
      to force renaming use -r insteed
"
#-------------------------------------------------------------------------------
#  import section
#-------------------------------------------------------------------------------
exiftoolLib_WithTrace=true
[[ -z ${exiftoolLib+x} ]] && source ${LIB_DIR}/exiftoolLib
[[ -z ${timerLib+x} ]] && source ${LIB_DIR}/timerLib

#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
declare timerName="${EXEC_NAME}"
timerReset ${timerName}
function reportDuration() {
  local topic=$1
  timerTop ${timerName}
  info "${topic} $(timerGetDuration ${timerName})"
  timerReset ${timerName}
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
readonly ACTION_CREATE="create"
readonly ACTION_REPLACE_3W="replace3W"
readonly ACTION_UPDATE_DS="fixDurationAndSize"
readonly FILENAME_PATTERN='s/^[a-z]*-[-.a-z0-9]*@[-.a-z]*\[[-,x0-9]*(,G)?\].*//'
declare exiftoolCommand=${EXIFTOOL_COMMAND}
declare explainMode="+x"

# parse options
while getopts ":h :v :t :e :u :r: :w:" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      TRACE=on
      trace "verbose mode"
      ;;
    t)
      exiftoolCommand="echo ${exiftoolCommand}"
      testMode=true
      trace "test mode"
      ;;
    e)
      explainMode="-x"
      trace "explain mode"
      ;;
    u)
      if [[ "${action}" != "" ]] ; then
        error "incompatible option mixed"
        usage
        exit 1
      fi
      action=${ACTION_UPDATE_DS}
      traceVar action
      ;;
    w)
    if [[ "${action}" != "" ]] ; then
        error "incompatible option mixed"
        usage
        exit 1
      fi
      www=( $echo ${OPTARG} )
      whoArg=${www[0]}
      whatArg=${www[1]}
      whereArg=${www[2]}
      traceVar www=${www[@]}
      action=${ACTION_CREATE}
      traceVar action
      ;;
    r)
    if [[ "${action}" != "" ]] ; then
        error "incompatible option mixed"
        usage
        exit 1
      fi
      www=( $echo ${OPTARG} )
      whoArg=${www[0]}
      whatArg=${www[1]}
      whereArg=${www[2]}
      traceVar www=${www[@]}
      action=${ACTION_REPLACE_3W}
      traceVar action
      ;;
    \?)
      error "Invalid option: -$OPTARG"
      usage
      exit 1
      ;;
    :)
      error "Option -$OPTARG requires an argument."
      usage
      exit 1
      ;;
  esac
done
shift $(( OPTIND-1 ))

# check if action is defined
if [[ "${action}" == "" ]] ; then
  error "action must be defined"
  usage
  exit 1
fi

if [[ "${action}" == "${ACTION_CREATE}" || "${action}" == "${ACTION_REPLACE_3W}" ]] ; then
  if (( ${#www[@]} != 3 )) ; then
    error "three <who> <what> and <where> strings must be provided"
    usage
    exit 1
  fi
fi

# check the number of parameters
if (( $# < 1 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

OFS="$IFS"
IFS=$'\n'

declare -i processed=0
declare -i renamed=0

reportDuration "options parsing"

END=$#
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  fullFileName=$1;                            traceVar fullFileName
  shift
  END=$#;                                     traceVar END

  (( processed++ ))

  # check if the file is a regular file
  if [[ ! -f ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: do not exist or not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: unable to read"
    continue
  fi

  # check if the file can be writen
  if [[ ! -w ${fullFileName} ]] ; then
    info "'${fullFileName}': ignore: unable to write"
    continue
  fi

  fileName=${fullFileName##*/};               traceVar fileName
  fileNameWithoutExtention=${fileName%.*};    traceVar fileNameWithoutExtention
  fileNamePatternMatching=$(echo ${fileNameWithoutExtention} | sed -re ${FILENAME_PATTERN})
  traceVar fileNamePatternMatching
  fileCategory=""

  case ${action} in
    ${ACTION_CREATE})
      if [[ "${fileNamePatternMatching}" == "" ]] ; then
        info "'${fileName}': unchanged: already match pattern"
        continue
      fi
      fileCategory=${fileCategory:="${whoArg}-${whatArg}@${whereArg}"}
      traceVar fileCategory
      ;;
    ${ACTION_REPLACE_3W})
      if [[ "${fileNamePatternMatching}" != "" ]] ; then
        info "'${fileName}': unchanged: did not match pattern"
        continue
      fi
      fileCategory=${fileCategory:="${whoArg}-${whatArg}@${whereArg}"}
      traceVar fileCategory
      ;;
    ${ACTION_UPDATE_DS})
      if [[ "${fileNamePatternMatching}" != "" ]] ; then
        info "'${fileName}': unchanged: did not match pattern"
        continue
      fi
      fileCategory=${fileName%[*.*}
      traceVar fileCategory
      ;;
    :)
      fatal "wrong action"
      ;;
  esac

  geoTag=$(exiftool -n -gpsposition ${fullFileName} | awk '{r = $4 + $5; if (r != 0) print ",G"}')

  CR=$(set ${explainMode} ; exiftool "-filename<${fileCategory}"'[${duration;s/:/-/g;s/([0-9][0-9])(\.[0-9]*)( s)/0-00-$1/;s/([0-9])(\.[0-9]*)( s)/0-00-0$1/},${Imagesize}'${geoTag}']%-c.%e' ${fullFileName})
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    continue
  else
    status=$(echo $CR | sed -e "s/0 image files.*1 image files[ ]*//" -e "s/1 image files[ ]*//")
    [[ "${status}" == "updated" ]] && (( renamed++ ))     ### TO FIX
    info "'${fileName}':${status}"
  fi

  (( renamed++ ))

done
IFS="$OFS"

reportDuration "renaming ${renamed} out of ${processed} in"
