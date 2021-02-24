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
readonly USAGE='usage: %s [-h] [-v] [-e] <source files>'
readonly HELP="
Convert webp files to either gif or jpg for respectivelly animated of fixed pictures
  -h: display this help
      ignore any other options and parameters
  -e: explain mode
  -v: verbose mode
"
#-------------------------------------------------------------------------------
# import section
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare explainMode="+x"
declare DELAY=${DELAY:-10}
declare LOOP=${LOOP:-0}

# parse options
while getopts ":h :e :v" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    e)
      explainMode="-x ;"
      trace "explain mode"
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
  fileToProcess=$1;                               traceVar fileToProcess
  shift
  END=$#;                                         traceVar END

  # check if the file is a regular file
  if [[ ! -f ${fileToProcess} ]] ; then
    info "'${fileToProcess}' : ignore: do not exist or not a regular file"
    continue
  fi

  # check if the file can be read
  if [[ ! -r ${fileToProcess} ]] ; then
    info "'${fileToProcess}' : ignore: unable to read"
    continue
  fi

  realPath=$(realpath $fileToProcess)
  dirName=$(dirname ${realPath})
  filename=$(basename ${realPath})

  pushd "${dirName}" > /dev/null

  frameNumber=$(webpinfo -summary ${filename} | grep frames | sed -e 's/.* \([0-9]*\)$/\1/')
  duration=$(webpinfo -summary ${filename} | grep Duration | head -1 |  sed -e 's/.* \([0-9]*\)$/\1/')

  if [ "${duration}" == "" ] ; then
    trace "No duration found, converting to jpg" >&2
    convert ${filename} ${filename}.jpg
    continue
  fi

  if (( ${duration} > 0 )); then
      DELAY=${duration}
  fi

  prefix=$(echo -n ${filename} | sed -e 's/^\(.*\).webp$/\1/')
  if [ -z ${prefix} ]; then
    pfx=${filename}
  fi

  trace "converting ${frameNumber} frames from ${filename}
  working dir ${dirName}
  file stem '${prefix}'" >&2

  for i in $(seq -f "%05g" 1 ${frameNumber})
  do
    webpmux -get frame $i ${filename} -o ${prefix}.$i.webp
    dwebp ${prefix}.$i.webp -o ${prefix}.$i.png
  done

  convert ${prefix}.*.png -delay $DELAY -loop $LOOP ${prefix}.gif
  rm ${prefix}.[0-9]*.png ${prefix}.[0-9]*.webp

  popd > /dev/null

  hasProcessed=full
  reportDuration "file processing time"

done

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing time"
