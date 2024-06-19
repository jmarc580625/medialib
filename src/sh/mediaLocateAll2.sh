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
readonly USAGE='usage: %s [-d] [-f] [-h] [-o <outfile>] [-v]'
readonly HELP="
Extract GSP location for all media files in the current and sub directories and
generates a html output into an 'index.html' file
  -d: restricts processed file in the curent directory
  -f: forces processing when status file is newer than its corresponding file
  -h: display this help
      Ignore any other option and parameter
  -o: redirect output to the specified outfile
      default output is 'index.html'
      uses '-' to direct output to standard directory
  -v: verbose mode
"
#-------------------------------------------------------------------------------
# TODO list
#-------------------------------------------------------------------------------
: "
- restrict find to media files
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${exiftoolLib+x} ]] && source ${LIB_DIR}/exiftoolLib
#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
function processMedia {
 
  local -r readonly STATUS_NEW=".tmp"
  local -r STATUS_DONE=".done" 
  local -r STATUS_IGNORE=".ignore"

  local fileToProcess=$1
  local fileCurentStatus=$2
  local fileHash=${fileCurentStatus%.*}
  local fileStatus=${fileCurentStatus##*.}

  local statusIsNew=0   ; [[ ".${fileStatus}" == "${STATUS_NEW}" ]]  && statusIsNew=1
  local statusIsDone=0  ; [[ ".${fileStatus}" == "${STATUS_DONE}" ]] && statusIsDone=1

  local exiftoolScript="${LIB_DIR}/mediaLocateFindGPS" ; traceVar exiftoolScript
  
  local gpsData=$(exiftool -n -p "${exiftoolScript}" "${fileToProcess}" 2>/dev/null)

  if [[ -n "${gpsData}" ]] ; then
    echo "${gpsData};${fileHash}" | tr -d '\r'
    if (( statusIsNew )) ; then
      mv -f "${fileCurentStatus}" "${fileHash}${STATUS_DONE}" #>/dev/null 2>&1
    fi
    touch "${fileHash}${STATUS_DONE}" #>/dev/null 2>&1
  else
    mv -f "${fileCurentStatus}" "${fileHash}${STATUS_IGNORE}" #>/dev/null 2>&1
  fi
}
export -f processMedia

function fpm {
  echo "$1, $2"
}
export -f fpm

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare   forceMode=""
declare   maxDepthSearch=""
declare   memoryPath=./.mediaLocate
declare   outputFile="index.html"
declare   outputTempFile="$$.tmp" 
declare   outputSpec="cat > ${outputTempFile}"
declare   outToStdout=0
#readonly  FIND_NAME_FILTER=' \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mp4" -o -iname "*.3gp" -o -iname "*.avi" -o -iname "*.mov" \) '


# parse options
while getopts ":h :t :f :d :o: :v" opt; do
  case ${opt} in
    d)
      maxDepthSearch="-maxdepth 1"
      trace "force search in current directory only"
      ;;
    f)
      forceOption="-f"
      trace "force mode"
      ;;
    h)
      help
      exit 0
      ;;
    o)
      outputFile=${OPTARG};
      if [[ "${outputFile}" == '-' ]] ; then
        outToStdout=1
        outputSpec="cat"
        trace "output to stdout"
      else
        trace "output to ${outputFile}"
      fi
      ;;
    t)
      TRACE=on
      awkVerboseMode="-v verbose=1"
      trace "verbose mode"
      ;;
    v)
      verboseOption="${verboseOption} -v "
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
if (( $# > 0 )) ; then
  error "Invalid number of parameters"
  usage
  exit 1
fi

awkScript="${LIB_DIR}/mediaLocateOut2HTML"    ; traceVar awkScript

mkdir -p "${memoryPath}"

if (( ! outToStdout )) ; then
  outputTempFile="${memoryPath}/${outputTempFile}"
  outputSpec="cat > ${outputTempFile}"
fi

find . -path "${memoryPath}" -prune -o -type f ${FIND_NAME_FILTER} ${maxDepthSearch} -print |\
  ${EXEC_HOME}/processMemory ${verboseOption} ${forceOption} "${memoryPath}" ${options} processMedia |\
    awk -f ${awkScript} ${awkVerboseMode} -v thumbDir=${memoryPath} -F \; |\
      eval ${outputSpec}

if (( ! outToStdout )) ; then
  if [[ -s  ${outputTempFile} ]] ; then
    mv ${outputTempFile} ${outputFile}
  else
    rm -f ${outputTempFile}
  fi
fi
# --profile=mediaLocate.prof 
