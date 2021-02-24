#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
# get script location
EXEC_HOME=${0%/*}
LIB_DIR=$(realpath ${EXEC_HOME}/../lib)
source ${LIB_DIR}/coreLib.sh
#-------------------------------------------------------------------------------
# usage & help
#-------------------------------------------------------------------------------
readonly USAGE='usage: %s [-h] [-t] [-v]  <source files>'
readonly HELP="
Transform videos in animated gif
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib.sh
[[ -z ${ffmpegLib+x} ]] && source ${LIB_DIR}/ffmpegLib.sh
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare outSuffix=""
declare outExtention="gif"

declare ffmpegCommand=${FFMPEG_COMMAND}
declare FPS=$4
declare SCALE=$3
declare PALETTE="/tmp/palette.png"
declare FILTERS="fps=${FPS},scale=${SCALE}:-1:flags=lanczos"

# parse options
while getopts ":h :t :v" opt; do
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
    f)
      forceVideoGeneration=1
      trace "force mode"
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

# iterate over source parameters
END=$#
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  inFileName=$1 ;traceVar inFileName
  shift
  END=$# ;traceVar END

  # check if the file is a regular file
  if [[ ! -f ${inFileName} ]] ; then
    info "'${inFileName}' :ignore:do not exist or not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${inFileName} ]] ; then
    info "'${inFileName}' :ignore:unable to read"
    continue
  fi

  outFileName=$(getoutFileName ${inFileName} ${outSuffix} ${outExtention}); traceVar outFileName
  ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i "${inFileName}" -vf "${FILTERS},palettegen" -y "${PALETTE}"
  ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i "${inFileName}" -i ${PALETTE} -lavfi "${FILTERS} [x]; [x][1:v] paletteuse" -y "${outFileName}"

done
