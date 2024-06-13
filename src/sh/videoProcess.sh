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
Process video filesaccording to naming patttern
- *-C.*           for automatic cropping
- *-C[09-].*      for defined cropping
- *-R[09].*       for defined rotating
- *-S.*           for automatic resizing
- *-S[09x].* for defined resizing
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------
[[ -z ${renameFileLib+x} ]] && source ${LIB_DIR}/renameFileLib
[[ -z ${timerLib+x} ]]      && source ${LIB_DIR}/timerLib

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

# iterate over source parameters
END=$#
trace "number of file to process: ${END}"
while (( END > 0 )) ; do
  fileName=$1;                                    traceVar fileName
  shift
  END=$#;                                         traceVar END

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

  if [[ ${fileName} =~ .*-R[0-9]+\..* ]] ; then
    a=${fileName##*R}; rotSpec=${a%.*}
    videoRotate -r ${rotSpec} ${fileName}
  elif  [[ ${fileName} =~ .*-S[0-9]+x[0-9]+\..* ]] ; then
    a=${fileName##*S}; sizeSpec=${a%.*}
    videoResize -efs ${sizeSpec} ${fileName}
  elif  [[ ${fileName} =~ .*-S\..* ]] ; then
    videoResize -efo ${fileName}
  elif  [[ ${fileName} =~ .*-C[0-9]+-[0-9]+-[0-9]+-[0-9]+\..* ]] ; then
    a=${fileName##*C}; b=${a%.*} ; cropSpec=${b//-/:}
    videoCrop -efc ${cropSpec} ${fileName}
  elif  [[ ${fileName} =~ .*-C\..* ]] ; then
    videoCrop -ef ${fileName}
  elif  [[ ${fileName} =~ .*-X[0-9]+.[0-9]+-[0-9]+.[0-9]+\..* ]] ; then
    a=${fileName##*X}; b=${a%.*} ; cropSpec=${b//-/:}
    videoExtract -efc ${cropSpec} ${fileName}
  elif  [[ ${fileName} =~ .*-X[0-9]+.[0-9]+\..* ]] ; then
    a=${fileName##*X}; cropSpec=${a%.*}
    videoExtract -efc ${cropSpec} ${fileName}
  else
    info "'${fileName}' : ignored"
  fi
done
