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
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] [-x <start index>:<duration>] <source files>'
readonly HELP="
Resize video files to closest standard aspect ratio
No action is taken when current video aspect ratio matches standard ratio
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -x: extract video sequence
      extract spec must conform the following syntax: <start index>[:<duration>]
      both being expressed in seconds
      if duration is omited, the extracted sequence lasts until the end of the video
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
declare explainMode="+x"

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
      explainMode="-x ;"
      trace "explain mode"
      ;;
    x)
      extract=${OPTARG};
      if [[ "${extract}" =~ ^[0-9]+$ ]] ; then
        startExtract=${extract}
      elif [[ "${extract}" =~ ^[0-9]+:[0-9]+$ ]] ; then
        read -r startExtract lengthExtract <<< ${extract/:/ }
      else
        fatal bad extract syntax
      fi
      ffmpegSeekOption=$(getFfmpegSeekOption ${startExtract})
      ffmpegTimeOption=$(getFfmpegTimeOption ${lengthExtract})
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
if (( $# < 1 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

reportDuration "options parsing"

# iterate over source parameters
END=$#
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  fileName=$1;                                    traceVar fileName
  shift
  END=$#;                                         traceVar END

  [[ "${hasProcessed}" == "short" ]] && reportDuration "file processing time"
  hasProcessed=short

  # check if the file is a regular file
  if [[ ! -f ${fileName} ]] ; then
    info "'${fileName}' : ignore: do not exist or not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${fileName} ]] ; then
    info "'${fileName}' : ignore: unable to read"
    continue
  fi

  newFileName=$(getNewFileName "${fileName}" "_X${extract}")
  traceVar newFileName
  info "'${fileName}' : extracting"
  $(set ${explainMode} ; ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i ${fileName} ${ffmpegSeekOption} ${ffmpegTimeOption} -vcodec copy -acodec copy ${FFMPEG_PRESERVE_METADATA_OPTION} ${newFileName})
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    rm -f ${outFileName}
  fi

  hasProcessed=full
  reportDuration "file processing time"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing time"
