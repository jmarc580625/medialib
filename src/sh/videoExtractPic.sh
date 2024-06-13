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
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] [-i <index>] [-c <number>] [-s <sensitivity>] <source files>'
readonly HELP="
Resize video files to closest standard aspect ratio
No action is taken when current video aspect ratio matches standard ratio
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -c: extract scene change pictures
  -s: scene change sentivity is a decimal value 0.x
      this option only applies in conjunction with the -c option
  -i: extract picture at the specified  index
      the index express a duration from the begining of the video
      if start index is omited, the picture is extracted from the first i-frame
      index can be expressed as following
        <seconds>.<fraction of seconds>
        00:00:00.000 - the nanoseconds part is optional (decimal point and three followinf digits)
In absence of extraction option the defaut option is set to -s 1
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
declare changeSensitivity=0.5
declare numberOfPictures=1
declare ffmpegSelectOption="-vf  select=gt(scene\,%s) -vsync vfr"
declare ffmpegNumberOfFramesOption="-frames:v %s"
# parse options
while getopts ":h :t :e :v :i: :c: :s:" opt; do
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
    i)
      startExtract=${OPTARG}
      ffmpegSeekOption=$(getFfmpegSeekOption ${startExtract})
      ;;
    c)
      numberOfPictures=${OPTARG}
      if [[ ! "${numberOfPictures}" =~ ^[0-9]+$ ]] ; then
        error bad syntax for number of scene pictures
        exit
      fi
      ffmpegSeekOption=""
      ;;
    s)
      changeSensitivity=${OPTARG}
      if [[ ! "${changeSensitivity}" =~ ^0.[0-9]$ ]] ; then
        error bad syntax for change scene sensitivity parameter
        exit
      fi
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

  printf -v ffmpegNumberOfFramesOption -- "${ffmpegNumberOfFramesOption}" ${numberOfPictures}
  if [[ "${ffmpegSeekOption}" == "" ]] ; then
    printf -v ffmpegSelectOption -- "${ffmpegSelectOption}" ${changeSensitivity}
  else
    ffmpegSelectOption=${ffmpegSeekOption}
  fi

  newFileName=$(getNewFileName "${fileName}" "" "jpg")
  traceVar newFileName
  info "'${fileName}' : extracting"
#  $( ${explainMode} ; ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i ${fileName} ${ffmpegSeekOption} ${ffmpegTimeOption} -vcodec copy -acodec copy ${FFMPEG_PRESERVE_METADATA_OPTION} ${newFileName})
  $( ${explainMode} ; ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i ${fileName} ${ffmpegSelectOption} ${ffmpegNumberOfFramesOption} ${newFileName})
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    rm -f ${outFileName}
  fi

  hasProcessed=full
  reportDuration "file processing time"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing time"
