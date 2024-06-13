#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
# get script location
EXEC_HOME=${0%/*}
LIB_DIR=$(realpath ${EXEC_HOME}/../lib)
source ${LIB_DIR}/coreLib
#-------------------------------------------------------------------------------
# TODO
# calculate croping surface
# define croping surface threashold under which croping is not performed
# delay after which cropdetect starts
# define crop zone
#-------------------------------------------------------------------------------
# usage & help
#-------------------------------------------------------------------------------
readonly USAGE='usage: %s [-h] [-t] [-v] [-e] [-f] [-r] [-x] [-d delay] [-c croppingSpec] [-l croppingLimit] <source files>'
readonly HELP="
Crop video files to remove black border
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
  -e: explain mode
  -r: report identified cropping zone only
  -x: test cropping on first 10 seconds
  -f: force cropping and ignore limits
  -c: define cropping zone which supercede crop detection <width>:<height>:<x>:<y>
  -d: define delay after which crop detection starts to skip video trailer
      default is adaptative depending on video duration
TO BE IMPLEMENTED
  -l: define cropping limit under which cropping is not performed
      default is ${THREASHOLD_UPPER_CROP_RATIO}%
  -x: resize the video on a limited extract
      extract spec must conform the following syntax: <start index>:<duration>
      both being expressed in seconds
"
#-------------------------------------------------------------------------------
# import section
ffmpegLib_WithTrace=true
#videoSizingLib_WithTrace=true
[[ -z ${ffmpegLib+x} ]]       && source ${LIB_DIR}/ffmpegLib
[[ -z ${videoSizingLib+x} ]]  && source ${LIB_DIR}/videoSizingLib
[[ -z ${renameFileLib+x} ]]   && source ${LIB_DIR}/renameFileLib
[[ -z ${timerLib+x} ]]        && source ${LIB_DIR}/timerLib
# enableTrace

#-------------------------------------------------------------------------------
# functions
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
declare THREASHOLD_UPPER_CROP_RATIO=45      ; traceVar THREASHOLD_UPPER_CROP_RATIO
declare THREASHOLD_LOWER_CROP_RATIO=0       ; traceVar THREASHOLD_LOWER_CROP_RATIO
declare ffmpegSeekOption=""
declare ffmpegSampleOption=""
declare ffmpegCommand=${FFMPEG_COMMAND}
declare explainMode=":"

# parse options
while getopts ":h :t :e :v :r :f :x :c: :d:" opt ; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      setTraceOn
      trace "verbose mode"
      ;;
    t)
      ffmpegCommand="echo ${FFMPEG_COMMAND}"
      trace "test mode"
      ;;
    e)
      explainMode="set -x"
      trace "explain mode"
      ;;
    c)
      spec=${OPTARG}; traceVar cropSpec
      [[ ! "${spec}" =~ ^[0-9]+\:[0-9]+\:[0-9]+\:[0-9]+$ ]] && fatal bad crop specificartion syntax
      cropSpec="crop=${spec}"
      specMode=true
      trace "spec mode"
      ;;
    r)
      trace "report mode"
      reportMode=true
      ;;
    f)
      trace "force mode"
      forceMode=true
      ;;
    x)
      sampleMode="-x"
      ffmpegSampleOption="-t 10"
      trace "sample mode"
      ;;
    d)
      forcedSkipDelay=${OPTARG};
      ! isInteger "${forcedSkipDelay}" && fatal bad delay syntax
      trace "force seek duration"
      ffmpegSeekOption=$(getFfmpegSeekOption ${forcedSkipDelay})
      forceSkipMode=true
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
END=$#;         traceVar END
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  fileName=$1;  traceVar fileName
  shift
  END=$#;       traceVar END

  [[ "${hasProcessed}" == "short" ]] && reportDuration "file processing time"
  hasProcessed=short

  # check if the file is a regular file
  if [[ ! -f ${fileName} ]] ; then
    info "'${fileName}': ignore: does not exist or is not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${fileName} ]] ; then
    info "'${fileName}': ignore: unable to read"
    continue
  fi

  if [[ "${forceSkipMode}" != "true" ]] ; then
    videoDuration=$(getVideoDuration  "${fileName}") ; traceVar videoDuration
    ffmpegSeekOption=$(getFfmpegAdaptativeSeekOption "${videoDuration}")
  fi ; traceVar ffmpegSeekOption
  if [[ "${specMode}" != true ]] ; then
    cropSpec=$(
      ${explainMode}
      ${ffmpegCommand/echo/} \
        ${ffmpegSeekOption} \
        -i $fileName \
        -t 1 -vf cropdetect \
        -f null - 2>&1 |
          awk '/crop/{print $NF}' |
            tail -n1
    )
  fi
  traceVar cropSpec

  videoSize=$(getVideoSize "${fileName}")     ; traceVar videoSize
  cropSize=$(cropSpec2CropSize "${cropSpec}") ; traceVar cropSize

  if [[ "${videoSize}" == "${cropSize}" ]] ; then
    info "'${fileName}': unchanged: same size ${cropSpec}"
    continue
  fi

  cropSizeDiff=$(getVideoSurfaceDiff "${videoSize}" "${cropSize}") ; traceVar cropSizeDiff
  if (( cropSizeDiff <=  0 )) ; then
    info "'${fileName}': unchanged: higer size ${cropSpec}"
    continue
  fi

  cropRatio=$(getVideoSurfaceRatio "${videoSize}" "${cropSize}");  traceVar cropRatio
  traceVar forceMode
  traceVar THREASHOLD_LOWER_CROP_RATIO
  traceVar THREASHOLD_UPPER_CROP_RATIO
  if [[ ( (( cropRatio < THREASHOLD_LOWER_CROP_RATIO )) || (( cropRatio > THREASHOLD_UPPER_CROP_RATIO )) ) && "${forceMode}" != true ]] ; then
    info "'${fileName}': unchanged: ${cropSpec} ratio ${cropRatio}% out of bound"
    continue
  fi

  if [[ "${reportMode}" == "true" ]] ; then
    info "'${fileName}': cropped: ${cropSpec} ratio ${cropRatio}%"
    continue
  fi

  outFileName=$(getNewFileName "${fileName}" "_cropped${cropRatio}" "mp4") ; traceVar outFileName

  info "'${fileName}': cropping: ${cropSpec} ratio ${cropRatio}%"
  (
    ${explainMode}
    ${ffmpegCommand}                      \
      ${FFMPEG_VERBOSE_OPTIONS}           \
      ${ffmpegSampleOption}               \
      -i ${fileName}                      \
      ${FFMPEG_ENCODING_QUALITY_OPTION}   \
      -vf ${cropSpec}                     \
      ${FFMPEG_PRESERVE_METADATA_OPTION}  \
      ${outFileName}
  )
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    rm -f ${outFileName}
  fi

  hasProcessed=full
  reportDuration "file processing time"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing time"
