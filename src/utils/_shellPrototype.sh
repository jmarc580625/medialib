#!/bin/bash

#-------------------------------------------------------------------------------
# Initialization
#-------------------------------------------------------------------------------
# get script location
EXEC_HOME=${0%/*}
source ${EXEC_HOME}/lib/coreLib.sh
#-------------------------------------------------------------------------------
# usage & help
#-------------------------------------------------------------------------------
readonly USAGE='usage: %s [-h] [-t] [-v]  <source files>'
readonly HELP="
Does something
  -h: display this help
      ignore any other options and parameters
  -t: test mode
  -v: verbose mode
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${EXEC_HOME}/lib/renameFileLib.sh
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare outSuffix=""
declare outExtention="EXT"

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

  # ONLY NEEDED WHEN INPUT FILE MUST BE MODIFIED/RENAMED
  # check if the file can be read
  if [[ ! -w ${inFileName} ]] ; then
    info "'${inFileName}' :ignore:unable to write"
    continue
  fi

  outFileName=$(getoutFileName ${inFileName} ${outSuffix} ${outExtention}); traceVar outFileName
  : 'PUT HERE WHATEVER THE SCRIPT HAS TO DO'
  echo ${EXEC_NAME}:PROTOTYPE:from ${inFileName} to ${outFileName}

done
