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
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] <source files> <destination file>'
readonly HELP="
concatenate several video into a single files file
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib
[[ -z ${ffmpegLib+x} ]]     && source ${LIB_DIR}/ffmpegLib
[[ -z ${timerLib+x} ]]      && source ${LIB_DIR}/timerLib

#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
declare timerName="${EXEC_NAME}"
timerReset ${timerName}
function reportDuration() {
  local topic=$1
  timerTop ${timerName}
  info "${topic}:$(timerGetDuration ${timerName})"
  timerReset ${timerName}
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare ffmpegCommand=${FFMPEG_COMMAND}
declare explainMode=":"

# parse options
while getopts ":h :t :e :v :x:" opt; do
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
      ffmpegCommand="echo ${ffmpegCommand}"
      trace "test mode"
      ;;
    e)
      explainMode="set -x"
      trace "explain mode"
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

# check the number of parameters
if (( $# < 3 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

reportDuration "options parsing"

# iterate over source parameters
END=$#

while (( END > 1 )) ; do
  fileName=$1;                                    traceVar fileName
  shift
  END=$#;                                         traceVar END

  # check if the file is a regular file
  if [[ ! -f ${fileName} ]] ; then
    error "'${fileName}' : ignore: do not exist or not a regular file"
    exit
  fi

  # check if the file can be read
  if [[ ! -r ${fileName} ]] ; then
    error "'${fileName}' : ignore: unable to read"
    exit
  fi

  sourceVideos+=("file '$(realpath ${fileName})'")

done

targetFile=$1;                                    traceVar targetFile
(
  ${explainMode}
  ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -f concat -safe 0  -i <(printf '%s %s\n' ${sourceVideos[@]})  ${FFMPEG_PRESERVE_METADATA_OPTION} ${targetFile}
)
if [[ $? != 0 ]] ; then
  warning "'${targetFile}': failed to merge: with return code $?"
  rm -f ${targetFile}
fi

rm -f ${tempList}

reportDuration "file processing time"
