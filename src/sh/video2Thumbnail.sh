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
readonly USAGE='usage: %s [-h] [-t] [-v] [-x <width> | -y <height> | -s <size>] <video file> [<thumbnail file>]'
readonly HELP="
Extract thumbnail image from the video and encode it in B64
By default image is set with a width of 128 pixel.
When many size settings are provided, the lastone is applied.
When a thumbnail file name is provided the extracted thumbnail image is stored into the file.

  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -x: force thumbnail width to <width>
  -y: force thumbnail height to <height>
  -s: force thumbnail size. Size must follow the syntax: <width>x<height>
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${ffmpegLib+x} ]] && source ${LIB_DIR}/ffmpegLib
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare ffmpegCommand=${FFMPEG_COMMAND}
declare ffmpegOutput="-f image2pipe - | base64"
declare thumbnailScale="scale=128:-1"

# parse options
while getopts ":h :v :t :x: :y: :s: " opt; do
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
      testMode=true
      trace "test mode"
      ;;
    x)
      [[ ! "${forcedThumbnailScale}" = "" ]] && trace multiple scale setting
      width=${OPTARG};
      [[ ! "${width}" =~ ^[0-9]+$ ]] && error bad width syntax: ${width} && exit 1
      forcedThumbnailScale="scale=${width}:-1"
      thumbnailScale=${forcedThumbnailScale}
      trace "force thumbnail width to ${width}"
      ;;
    y)
      [[ ! "${forcedThumbnailScale}" = "" ]] && trace multiple scale setting
      height=${OPTARG};
      [[ ! "${height}" =~ ^[0-9]+$ ]] && error bad height syntax: ${height} && exit 1
      forcedThumbnailScale="scale=-1:${height}"
      thumbnailScale=${forcedThumbnailScale}
      trace "force thumbnail height to ${height}"
      ;;
    s)
      [[ ! "${forcedThumbnailScale}" = "" ]] && trace multiple scale setting
      scale=${OPTARG};
      [[ ! "${scale}" =~ ^[-0-9]+x[-0-9]+$ ]] && error bad scale syntax: ${scale} && exit 1
      scale=${scale/x/:}
      forcedThumbnailScale="scale=${scale}"
      thumbnailScale=${forcedThumbnailScale}
      trace "force thumbnail scale to ${scale}"
      ;;
    \?)
      error "Invalid option: -${OPTARG}"
      usage
      exit 1
      ;;
    :)
      error "Option -${OPTARG} requires an argument."
      usage
      exit 1
      ;;
  esac
done
shift $(( OPTIND-1 ))

# check the number of parameters
if (( $# < 1 )) || (( $# > 2 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

fileName=$1
output=$2
[[ ! "${output}" = "" ]] && ffmpegOutput=${output}

trace fileName=${fileName}
trace thumbnailScale=${thumbnailScale}
trace ffmpegOutput=${ffmpegOutput}

cmd="${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} -i ${fileName} -vf  "thumbnail,${thumbnailScale}" -frames:v 1 ${ffmpegOutput}"
trace cmd=${cmd}

[[ "${testMode}" = "true" ]] && echo "${cmd}" || eval $cmd
