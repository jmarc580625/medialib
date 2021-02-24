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
readonly USAGE='usage: %s [-h] [-t] [-v]'
readonly HELP="
Extract GSP location for all media files in the current and sub directories
  -h: display this help
      Ignore any other option and parameter
  -t: test mode
  -v: verbose mode
"
#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare     options=""
declare     maxDepthSearch=""

# parse options
while getopts ":h :t :v :f :c :s: :e:" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      TRACE=on
      options="${options} -${opt}"
      trace "verbose mode"
      ;;
    t)
      options="${options} -${opt}"
      trace "test mode"
      ;;
    f)
      options="${options} -${opt}"
      trace "force mode"
      ;;
    s)
      scale=${OPTARG}
      options="${options} -${opt} ${scale}"
      [[ ! "${scale}" =~ [0-9]+x[0-9]+ ]] && error bad scale syntax && exit 1
      trace "force scale"
      ;;
    c)
      maxDepthSearch="-maxdepth 1"
      trace "force search in current directory only"
      ;;
    e)
      findExpression=${OPTARG};
      trace "change default search expression to ${findExpression}"
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

find . -type f ${maxDepthSearch} -exec ${EXEC_HOME}/mediaLocate.sh ${options} {} \;
