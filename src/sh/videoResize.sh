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
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] [-f] [-x] [-o] [-b <u|l|c>] [-s <scale>] <source files>'
readonly HELP="
Resize video files to closest standard aspect ratio
No action is taken when current video aspect ratio matches standard ratio
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -o: resize the video to the next scale after the target standard aspect ratio
  -f: resize the video even when the current aspect ratio matches standard ratio
  -x: test resizing on first 10 seconds
  -b: resize the video with defined strategy regarding standard aspect ratio
      u for upper; l for lower; c for closest
      default strategy is closest
  -s: resize the video with the provided scale
      provided scale must conform the following syntax: <width>x<height>
      imply -f
TO BE IMPLEMENTED
  -x: resize the video on a limited extract
      extract spec must conform the following syntax: <start index>:<duration>
      both being expressed in seconds
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib
[[ -z ${videoSizingLib+x} ]] && source ${LIB_DIR}/videoSizingLib
[[ -z ${ffmpegLib+x} ]] && source ${LIB_DIR}/ffmpegLib
[[ -z ${timerLib+x} ]] && source ${LIB_DIR}/timerLib
[[ -z ${utilLib+x} ]] && source ${LIB_DIR}/utilLib

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
declare -A targetStrategies
targetStrategies["u"]=${TARGET_UPPER}
targetStrategies["l"]=${TARGET_LOWER}
targetStrategies["c"]=${TARGET_CLOSER}
targetStrategies["d"]=${TARGET_CLOSER}
declare ffmpegCommand=${FFMPEG_COMMAND}
declare ffmpegSampleOption=""
declare explainMode=":"


# parse options
while getopts ":h :t :e :v :f :o :x :b: :s:" opt; do
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
    x)
      sampleMode="-x"
      ffmpegSampleOption="-t 10"
      trace "sample mode"
      ;;
    f)
      forceVideoGeneration=1
      trace "force mode"
      ;;
    o)
      overSize=yes
      trace "oversize mode"
      ;;
    b)
      targetStrategy=${OPTARG};
      [[ ! "${targetStrategy}" =~ ^[culd]$ ]] && error bad trategy value && exit 1
      traceVar targetStrategy
      sizeStrategy=${targetStrategies["${targetStrategy}"]}
      traceVar sizeStrategy
      trace "target strategy set to ${sizeStrategy}"
      ;;
    s)
      forcedVideoSize=${OPTARG};
      [[ ! "${forcedVideoSize}" =~ ^[0-9]+x[0-9]+$ ]] && error bad scale syntax && exit 1
      forceVideoGeneration=1
      trace "force scale to ${forcedVideoSize}" ; set +x
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
shift $((OPTIND-1))

reportDuration "options parsing"

# check the number of parameters
if (( $# < 1 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

declare -i processed=0
declare -i resized=0

# iterate over source parameters
END=$#
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  fileName=$1;                                    traceVar fileName
  shift
  END=$#;                                         traceVar END

  (( processed++ ))

  [[ "${hasProcessed}" == "short" ]] && reportDuration "file processing"
  hasProcessed=short

  # check file Access
  checkReadAccessFile ${fileName} || continue

  if [[ "${forcedVideoSize}" != "" ]] ; then
    newVideoSize=${forcedVideoSize}
  else
    videoSize=$(getVideoSize ${fileName});    traceVar videoSize
    newVideoSize=$(getNewVideoSize ${videoSize} ${videoWidth} "${overSize}" "${sizeStrategy}")
  fi
  traceVar newVideoSize

  #convert video to determined scale
  if [[ "${videoSize}" != "${newVideoSize}" || ${forceVideoGeneration} ]] ; then
    newFileName=$(getNewFileName ${fileName} "_S${newVideoSize}" "mp4")
    traceVar newFileName

    info "'${fileName}': resizing: ${newVideoSize}"
    (
      ${explainMode}
      ${ffmpegCommand}                          \
        ${FFMPEG_VERBOSE_OPTIONS}               \
        ${ffmpegSampleOption}                   \
        -i ${fileName}                          \
        ${FFMPEG_ENCODING_QUALITY_OPTION}       \
        -vf "scale=${newVideoSize},setsar=1/1"  \
        ${FFMPEG_PRESERVE_METADATA_OPTION}      \
        ${newFileName}
    )
    if [[ $? != 0 ]] ; then
      warning "'${fileName}': failed: with return code $?"
      rm -f ${newFileName}
    fi
  else
    info "'${fileName}': unchanged"
  fi

  (( resized++ ))

  hasProcessed=full
  reportDuration "file processing"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing"
reportDuration "resizing ${resized} out of ${processed} in"
