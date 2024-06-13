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
readonly USAGE="usage: ${EXEC_NAME} [-e] [-h] [-t] [-v] [-w] [<media file> | <directory>]"
readonly HELP="
Extract GPS locatiopn information when exists from designated media file
or mediafiles within the designated directory. When no media file or directory
is provided all files in the current directory and its sub-directories are
processed.
Extracted information is organized in csv (coma sepatated values) form:
  <latitude>;<longitude>;<file path>
Where <file path> is relative to the current directory.
  -e: explain
  -h: display this help
      ignore any following options and parameters
  -t: test mode
  -v: verbose mode
  -w: generate web page with links to the media and to google maps in place of
      the csv form
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${exiftoolLib+x} ]] && source ${LIB_DIR}/exiftoolLib
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare exiftoolCommand=${EXIFTOOL_COMMAND}
declare explain=":"

# parse options
while getopts ":e :h :t :v :w" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      TRACE=on
      awkVerboseMode="-v verbose=1"
      trace "verbose mode"
      set -x
      ;;
    t)
      trace "test mode"
      exiftoolCommand="echo ${exiftoolCommand}"
      ;;
    e)
      trace "explain mode"
      explain="set -x"
      ;;
    w)
      trace "web mode"
      webMode=true
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

fileList=("$@")
[ ${#fileList} -lt 1 ] && fileList+="."

awkScript="${LIB_DIR}/mediaLocateOut2HTML"    ; traceVar awkScript
exiftoolScript="${LIB_DIR}/mediaLocateFindGPS" ; traceVar exiftoolScript

if [[ "${webMode}" == true ]] ; then
  thumbDir=".${EXEC_NAME}"                  ; traceVar thumbDir
  processing=" | tr -d '\015' | awk -f ${awkScript} ${awkVerboseMode} -v thumbDir=${thumbDir} -F \;"
  traceVar processing
fi

(
  ${explain};
  eval "${exiftoolCommand} -r -n -p ${exiftoolScript} ${fileList[@]} 2>/dev/null ${processing}"
)
