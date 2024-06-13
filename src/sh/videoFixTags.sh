#!/bin/bash

#set -x

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
readonly USAGE='usage: %s [-h] [-t] [-e] [-v] [-A <author>] [-C <creator>] [-K <keywords>] [-O | -D <description>] [-E <editor>] [-P <publisher>] [-S <source>] [-T <title>] <source files>'
readonly HELP="
Update exif tags for media files
  -h: display this help
      ignore any other options and parameters
  -v: verbose mode
  -e: explain mode
  -A: update <Author> tag
  -C: update <Creator> tag
  -E: update <Editor> tag, can be used to store website where the media is published
  -D: update <Description> tag, can be used to store original media filename for example
  -K: update <Keywords> tag
      list of coma separated words
  -O: uses curent file name as default text to fill description tag
  -P: update <Publisher> tag
  -T: update <Title> tag
  -S: update <Source> tag, can be used to store url for downlaoded media files for example
  -X: update additional tags according to the following rules
      tag setting must adhere to the following syntax : -<EXIF_TAG>=<TAG_VALUE>,
        where <EXIF_TAG> is a valid exiff modifiable tag
      several tag settings can be used in the command line
"
#-------------------------------------------------------------------------------
#  import section
#-------------------------------------------------------------------------------
exiftoolLib_WithTrace=true
[[ -z ${exiftoolLib+x} ]] && source ${LIB_DIR}/exiftoolLib
[[ -z ${timerLib+x} ]] && source ${LIB_DIR}/timerLib
[[ -z ${utilLib+x} ]] && source ${LIB_DIR}/utilLib

#-------------------------------------------------------------------------------
# functions
#-------------------------------------------------------------------------------
declare timerName="${EXEC_NAME}"
timerReset ${timerName}
function reportDuration() {
  local topic=$1
  timerTop ${timerName}
  info "${topic} $(timerGetDuration ${timerName})"
  timerReset ${timerName}
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
readonly TAG_AUTHOR="Author"              #
readonly TAG_CREATOR="Creator"            #
readonly TAG_DESCRIPTION="Description"    # original filemane
readonly TAG_EDITOR="Editor"              #
readonly TAG_KEYWORDS="Keywords"          #
readonly TAG_PUBLISHER="Publisher"        # origin web site
readonly TAG_SOURCE="Source"              # download url
readonly TAG_TITLE="Title"                #

declare exiftoolCommand=${EXIFTOOL_COMMAND}
declare exiftoolOptions="-overwrite_original"
declare explainMode=":"
declare useFileName4Description=no

# parse options
while getopts ":h :v :e :A: :C: :D: :E: :K: :O :P: :S: :T: :X:" opt; do
  case ${opt} in
    h)
      help
      exit 0
      ;;
    v)
      TRACE=on
      trace "verbose mode"
      ;;
    e)
      explainMode="set -x"
      trace "explain mode"
      ;;
    A)
      authorUpdate="-${TAG_AUTHOR}=${OPTARG}"
      traceVar authorUpdate
      ;;
    C)
      creatorUpdate="-${TAG_CREATOR}=${OPTARG}"
      traceVar creatorUpdate
      ;;
    D)
      descriptionUpdate="-${TAG_DESCRIPTION}=${OPTARG}"
      traceVar descriptionUpdate
      ;;
    E)
      editorUpdate="-${TAG_EDITOR}=${OPTARG}"
      traceVar editorUpdate
      ;;
    K)
      keywordsUpdate="-${TAG_KEYWORDS}=${OPTARG}"
      traceVar keywordsUpdate
      ;;
    O)
      useFileName4Description=yes
      traceVar useFileName4Description
      ;;
    P)
      publisherUpdate="-${TAG_PUBLISHER}=${OPTARG}"
      traceVar publisherUpdate
      ;;
    S)
      sourceUpdate="-${TAG_SOURCE}=${OPTARG}"
      traceVar sourceUpdate
      ;;
    T)
      titleUpdate="-${TAG_TITLE}=${OPTARG}"
      traceVar titleUpdate
      ;;
    X)
      extraUpdate+=("${OPTARG}")
      traceVar extraUpdate
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

#OFS="$IFS"
#IFS=$'\n'

declare -i processed=0
declare -i taged=0

# iterate over source parameters
END=$#
trace "number of file to process: ${#}"
while (( END > 0 )) ; do
  fullFileName=$1;                            traceVar fullFileName
  shift
  END=$#;                                         traceVar END

  (( processed++ ))

  [[ "${hasProcessed}" == "short" ]] && reportDuration "file processing"
  hasProcessed=short

  # check file Access
  checkReadAccessFile "${fullFileName}" || continue

  [ "${useFileName4Description}" == "yes" ] &&  descriptionUpdate="-${TAG_DESCRIPTION}=$(basename ${fullFileName})"

  (
    ${explainMode}
    IFS=$'\n'
    exiftool                \
      ${exiftoolOptions}    \
      ${authorUpdate}       \
      ${creatorUpdate}      \
      ${descriptionUpdate}  \
      ${editorUpdate}       \
      ${publisherUpdate}    \
      ${titleUpdate}        \
      ${sourceUpdate}       \
      ${keywordsUpdate}     \
      "${extraUpdate[@]}"   \
      ${fullFileName}
  )
  if [[ $? != 0 ]] ; then
    warning "'${fileName}': failed: with return code $?"
    continue
  fi

  (( taged++ ))

  hasProcessed=full
  reportDuration "file processing"
done
#IFS="$OFS"

[[ "${hasProcessed}" == "short" ]]  && reportDuration "file processing"
reportDuration "taging ${taged} out of ${processed} in"
(( taged < processed )) && exit 1 || exit 0
