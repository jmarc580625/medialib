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
readonly USAGE='usage: %s <source files>'
readonly HELP="
Analyzes video to idenfify cleanup actions like:
- removing black frames
- removing in intro and extro sequences
- resizing to get a width of either 480p or 720p
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${ffmpegLib+x} ]]       && source ${LIB_DIR}/ffmpegLib
[[ -z ${videoSizingLib+x} ]]  && source ${LIB_DIR}/videoSizingLib
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib
[[ -z ${timerLib+x} ]]      && source ${LIB_DIR}/timerLib
[[ -z ${utilLib+x} ]] && source ${LIB_DIR}/utilLib

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
# parse options
while getopts ":h :v" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      TRACE=on
      trace "verbose mode"
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

declare -i processed=0
declare -i taged=0

# iterate over source parameters
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

  videoSize=$(getVideoSize "${fileName}")
  videoLength=$(getVideoLength "${fileName}")

  # Get specs to remove intro & outro sequence from video
  #------------------------------------------------------
  declare mustBeExtracted=0
  declare extractFrom=0
  declare extractLength=${videoLength}
  # Get position after intro
  # Get position before extro
  # Define extact parameters
  declare introEnd=0
  declare extroStart=${videoLength}
set -x
  introEnd=$(blackIntroDetect ${fileName})
  echo $introEnd
exit
  extroStart=$(blackExtroDetect ${fileName} ${videoLength})
  if (( introEnd > 0 )) ; then
    extractFrom=$(getNextIFrameIndex ${fileName} ${introEnd})
    mustBeExtracted=1
  fi
  if (( extroStart < videoLength )) ; then
    extractLength=$(bc <<< "${extroStart} - ${extractFrom}")
    mustBeExtracted=1
  fi

  (( mustBeExtracted )) && info resized to ${extractFrom}-${extractLength} || info  no extraction

  # Get specs to crop video for removing black frame
  #-------------------------------------------------
  declare mustBeCropped=0
  declare cropWidth
  declare cropHeight
  declare cropFromX
  declare cropFromY
  declare cropOrientation
  # skip
  if (( mustBeExtracted )) ; then
    ffmpegSeekOption=${extractFrom}
  else
    ffmpegSeekOption=$(getFfmpegAdaptativeSeekOption ${videoLength})
  fi
  cropSpec=$(getCropSpec ${fileName} ${ffmpegSeekOption})
  cropSize=$(cropSpec2CropSize "${cropSpec}")
  if [[ "${videoSize}" != "${cropSize}" ]] ; then
    cropSizeDiff=$(getVideoSurfaceDiff "${videoSize}" "${cropSize}")
    if (( cropSizeDiff > 0 )) ; then
      mustBeCropped=1
      read -r cropWidth cropHeight cropFromX cropFromY <<< ${cropSpec//:/ }
      cropOrientation=$(getVideoOrientation ${cropWidth} ${cropHeight})
    fi
  fi

  (( mustBeCropped )) && info resized to ${cropSpec} || info no cropping

  # get specs to rotate video
  #----------------------------
  declare mustBeRotated=0
  declare rotateAngle

  (( mustBeRotated )) && info resized to ${rotateAngle} || info  no rotation

  # get specs to resize video to set its height to 480p or 780p
  #------------------------------------------------------------
  declare mustBeResized=0
  declare resizeWidth
  declare resizeHeight
  declare resizeOrientation=${ORIENTATION_LANDSCAPE}

  orientation=$(getVideoOrientation ${videoSize})
  if (( mustBeCropped)) ; then
    if [[ "${cropOrientation}" == ${ORIENTATION_LANDSCAPE} ]] ; then
      height=cropHeight
    else
      height=cropWidth
      resizeOrientation=${ORIENTATION_PORTRAIT}
    fi
  else
    if [[ "${orientation}" == ${ORIENTATION_LANDSCAPE} ]] ; then
      height=$(cut -d x -f 1 <<< ${videoSize})
    else
      height=$(cut -d x -f 2 <<< ${videoSize})
      resizeOrientation=${ORIENTATION_PORTRAIT}
    fi
  fi

  if (( height != 240 )) && (( height != 480 )) && (( height != 720 )) ; then
    mustBeResized=1
    from240=$(bc <<< "sqrt((240 - ${height})^2)")
    from480=$(bc <<< "sqrt((480 - ${height})^2)")
    from720=$(bc <<< "sqrt((720 - ${height})^2)")
    if (( ${from240} < ${from480} )) ; then
      resizeHeight=240
    elif (( ${from480} < ${from720} )) ; then
      resizeHeight=480
    else
      resizeHeight=720
    fi
    if [[ "${resizeOrientation}" == ${ORIENTATION_LANDSCAPE} ]] ; then
      resizeSpec="-2x${resizeHeight}"
    else
      resizeSpec="${resizeHeight}x-2"
    fi
  fi

  (( mustBeResized )) && info resized to ${resizeSpec} || info  no resizing

  (( taged++ ))
  hasProcessed=full
  reportDuration "file processing"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing"
reportDuration "taging ${taged} out of ${processed} in"
