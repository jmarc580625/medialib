#-------------------------------------------------------------------------------
# ffmpeg utilities
[[ -z ${ffmpegLib} ]] || \
(echo 'warning ffmpegLib.sh imported multiple times, protect import with [[ -z ${ffmpegLib+x} ]]' >&2)
readonly ffmpegLib=1

#-------------------------------------------------------------------------------
# get lib location
declare _FFMPEGLIB_LIB_PATH=${BASH_SOURCE%/*}
[[ -z ${traceLib+x} ]] && source ${_FFMPEGLIB_LIB_PATH}/traceLib.sh
unset _FFMPEGLIB_LIB_PATH

[[ "${ffmpegLib_WithTrace}" != "true" ]]   && disableTrace # disabling traceLib functions

#-------------------------------------------------------------------------------
# getting ffmpeg command path - private section
function _getFfmpegCommand () {
  local command=$(which ffmpeg 2>/dev/null)
  traceVar command
  [[ -z ${command+x} ]] && fatal "install ffmpeg"
  echo "${command} "
}

#-------------------------------------------------------------------------------
# quality options - private section

# Constant Bit Rate : -crf $level;       with level in [0-51]; 0=highest quality
# Variable Bit Rate : -qscale:v $level;  with level in [0-31]; 0=highest quality

declare _QUALITY_METRIC=CBR    ; traceVar _QUALITY_METRIC
#declare _QUALITY_METRIC="VBR"    ; traceVar _QUALITY_METRIC

declare -A _BRLow
_BRLow[CBR]=0
_BRLow[VBR]=0
readonly _BRLow
traceVar _BRLow

declare -A _BRHigh
_BRHigh[CBR]=51
_BRHigh[VBR]=31
readonly _BRHigh
traceVar _BRHigh

declare -A _BROption
_BROption[CBR]=' -crf %s '
_BROption[VBR]=' -qscale:v %s '
readonly _BROption
traceVar _BROption

declare -A _qualityLevels

function _initQualityLevel {
  local _HighQM=${_BRHigh[${_QUALITY_METRIC}]}                  ; traceVar _HighQM
  local _LowQM=${_BRLow[${_QUALITY_METRIC}]}                    ; traceVar _LowQM
  local _MediumQM=$((     (_HighQM    - _LowQM)    / 2 ))  ; traceVar _MediumQM
  local _MediumHighQM=$(( ((_HighQM   - _MediumQM) / 2 ) + _MediumQM ))  ; traceVar _MediumHighQM
  local _MediumLowQM=$((  ((_MediumQM - _LowQM)    / 2 ) + _LowQM ))     ; traceVar _MediumLowQM
  _qualityLevels["HIGH"]=${_LowQM}
  _qualityLevels["MEDIUM_HIGH"]=${_MediumLowQM}
  _qualityLevels["MEDIUM"]=${_MediumQM}
  _qualityLevels["MEDIUM_LOW"]=${_MediumHighQM}
  _qualityLevels["LOW"]=${_HighQM}
  _qualityLevels["DEFAULT"]=${_MediumQM}
  traceVar _qualityLevels
}
_initQualityLevel

# quality options - public section
function getFfmpegQualityOption  {
  local quality=$1 ; traceVar quality
  quality=${quality:=DEFAULT}
  local level=${_qualityLevels[${quality}]}     ; traceVar level
  if [[ "${level}" == "" ]] ; then
    warning "${FUNCNAME}:bad quality level"
    result=${FFMPEG_ENCODING_QUALITY_OPTION}
  else
    local option=${_BROption[${_QUALITY_METRIC}]}  ; traceVar option
    result=$(printf "${option}" ${level})
  fi
  echo ${result}
}
function setFfmpegQualityMetrics {
  local metric=$1 ; traceVar metric
  if [[ "${metric}" =~ ^(CBR|VBR)$ ]] ; then
    _QUALITY_METRIC=${metric} ; traceVar _QUALITY_METRIC
    _initQualityLevel
    FFMPEG_ENCODING_QUALITY_OPTION=$(getFfmpegQualityOption DEFAULT)
  else
    warning "${FUNCNAME}:bad quality Metric:must be CBR or VBR"
  fi
}

#-------------------------------------------------------------------------------
# duration option - public section
function getFfmpegTimeOption  {
  duration=$1 ; traceVar duration
  if [[ "${duration}" =~ ^[1-9][0-9]*$ ]] ; then
    echo "-t $(date -d@$1 -u +%H:%M:%S)"
  elif [[ "${duration}" == "0" ]] ; then
    echo
  elif [[ "${duration}" == "" ]] ; then
    echo
  else
    echo
    warning ${FUNCNAME}:bad duration
  fi
}

#-------------------------------------------------------------------------------
# seek option - private section
declare -A _videoDuration2seekDuration
#_videoDuration2seekDuration[0]=0
_videoDuration2seekDuration[5]=0
_videoDuration2seekDuration[10]=5
_videoDuration2seekDuration[15]=10
_videoDuration2seekDuration[30]=20
_videoDuration2seekDuration[60]=35
_videoDuration2seekDuration[120]=65
readonly _videoDuration2seekDuration

# seek option - public section
function getFfmpegSeekOption            {
  duration=$1 ; traceVar duration
  if [[ "${duration}" =~ ^[1-9][0-9]*$ ]] ; then
    echo "-ss $(date -d@$1 -u +%H:%M:%S)"
  elif [[ "${duration}" == "0" ]] ; then
    echo
  elif [[ "${duration}" == "" ]] ; then
    echo
  else
    echo
    warning ${FUNCNAME}:bad duration
  fi
}
function getFfmpegAdaptativeSeekOption  {
  local videoDuration=$1 ; traceVar videoDuration
  traceVar _videoDuration2seekDuration
  keys=$(for V in ${!_videoDuration2seekDuration[@]} ; do echo $V ; done | sort -n)
  traceVar keys
  for V in  ${keys} ; do
    traceVar V
    if (( V <= videoDuration )) ; then
      seekDuration=${_videoDuration2seekDuration[${V}]} ; traceVar seekDuration
    else
      break
    fi
  done
  getFfmpegSeekOption ${seekDuration}
}

#-------------------------------------------------------------------------------
# cropping geometry - private section
declare _cropTemp=${1/crop=/}

# cropping geometry - public section
function cropSpec2CropWidth     { echo ${1/crop=/} | cut -d: -f1 ; }
function cropSpec2CropHeight    { echo ${1/crop=/} | cut -d: -f2 ; }
function cropSpec2CropSize      { echo ${1/crop=/} | cut -d: --output-delimiter="x" -f1,2 ; }
function cropSpec2CropPosition  { echo ${1/crop=/} | cut -d: --output-delimiter="," -f3,4 ; }

#-------------------------------------------------------------------------------
# public variables
declare FFMPEG_COMMAND=$(_getFfmpegCommand)                 ; traceVar FFMPEG_COMMAND
readonly FFMPEG_VERBOSE_OPTIONS=' -hide_banner -v warning '  ; traceVar FFMPEG_VERBOSE_OPTIONS
readonly FFMPEG_PRESERVE_METADATA_OPTION=' -map_metadata 0 ' ; traceVar FFMPEG_PRESERVE_METADATA_OPTION
declare FFMPEG_ENCODING_QUALITY_OPTION=$(getFfmpegQualityOption) ; traceVar FFMPEG_ENCODING_QUALITY_OPTION

[[ "${ffmpegLib_WithTrace}" != "true" ]]   && enableTrace
