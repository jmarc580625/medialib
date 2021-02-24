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
readonly USAGE='usage: [-h] [-t] [-v] [-e] <source files>'
readonly HELP="
Rename files based on time stamp to clear date & time
  -h: display this help
      ignore any other options and parameters
  -v: verbose mode
  -e: explain mode
  -t: test mode
"
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare command="mv"
declare explainMode="+x"

# parse options
while getopts ":h :v :t" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      setTraceOn
      trace "verbose mode"
      set -x
      ;;
    t)
      command="echo ${command}"
      testMode=true
      trace "test mode"
      ;;
    e)
      explainMode="-x"
      trace "explain mode"
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
  fileName=$1;  traceVar fileName
  shift
  END=$#;       traceVar END

  # check if the file is a regular file
  if [[ ! -f ${fileName} ]] ; then
    info "'${fileName}':ignore:does not exist or is not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${fileName} ]] ; then
    info "'${fileName}':ignore:unable to read"
    continue
  fi

  # check if the file can be read
  if [[ ! -w ${fileName} ]] ; then
    info "'${fileName}':ignore:unable to write"
    continue
  fi

  fileExtention=${fileName##*.};  traceVar fileExtention
  timeStamp=${fileName%.*};       traceVar timeStamp

  if [[ ! "${timeStamp}" =~ ^1[0-9]+$ ]] ; then
    info  ${fileName} : ignore: file name is not a timestamp
  fi
  timeStamp=$(( timeStamp / 1000 ))                   ; traceVar timeStamp
  newName=$(date -d  @${timeStamp} "+%Y%m%d-%H%M-%S") ; traceVar newName

  $(set ${explainMode} ; ${command} ${fileName} "${newName}.${fileExtention}") && \
    info  ${fileName} : renamed to "${newName}.${fileExtention}"

done
