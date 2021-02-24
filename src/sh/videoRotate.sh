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
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] [-x] [-r <angle>] <source files>'
readonly HELP="
Resize video files to closest standard aspect ratio
No action is taken when current video aspect ratio matches standard ratio
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -x: test rotation on first 10 seconds
  -r: rotate the video with the provided angle expressed in degree
TO BE IMPLEMENTED
  -x: resize the video on a limited extract
      extract spec must conform the following syntax: <start index>:<duration>
      both being expressed in seconds
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib.sh
[[ -z ${ffmpegLib+x} ]]     && source ${LIB_DIR}/ffmpegLib.sh
[[ -z ${timerLib+x} ]]      && source ${LIB_DIR}/timerLib.sh

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
# define filter
#-------------------------------------------------------------------------------
function getFilter () {
  case ${1} in
    "90")
      echo "transpose=1"
      ;;
    "-90")
      echo "transpose=2"
        ;;
    "180")
      echo "transpose=2,transpose=2"
      ;;
    "-180")
      echo "transpose=2,transpose=2"
        ;;
    "270")
      echo "transpose=2"
      ;;
    "-270")
      echo "transpose=1"
        ;;
    *)
      echo "rotate=${1}*(PI/180)"
      ;;
  esac
}
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare ffmpegCommand=${FFMPEG_COMMAND}
declare ffmpegSampleOption=""
declare explainMode="+x"

# parse options
while getopts ":h :t :e :x :v :r:" opt; do
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
      sampleMode="-x"
      ffmpegSampleOption="-t 10"
      trace "sample mode"
      ;;
    r)
      rotation=${OPTARG};
      [[ ! "${rotation}" =~ ^[-]?[0-9]+$ ]] && fatal bad angle syntax
      trace "rotation angle ${rotation}"
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

  newFileName=$(getNewFileName "${fileName}" "_R${rotation}" "mp4")
  traceVar newFileName
  filter=$(getFilter "${rotation}");  traceVar filter

  info "'${fileName}': rotating: ${rotation}"
  $(set ${explainMode} ; ${ffmpegCommand} ${FFMPEG_VERBOSE_OPTIONS} ${ffmpegSampleOption} -i ${fileName} ${FFMPEG_ENCODING_QUALITY_OPTION} -vf ${filter} ${FFMPEG_PRESERVE_METADATA_OPTION} ${newFileName})
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    rm -f ${outFileName}
  fi

  hasProcessed=full
  reportDuration "file processing time"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing time"
