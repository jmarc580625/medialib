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
readonly USAGE='usage: %s [-c] [-f] [-h] [-p] [-t] [-v] memory_directory processing_command'
readonly HELP="
reads a stream of file names and uses the memory_directory optimize their batch processing
memory_directory is used to remember file processing status 
file processing status is the combination of file name hash and status extension
extension are
    .tmp for file with ongoing process
    .ignore for file already processed that must be ignored by subsequents processing 
    .done for file already processed that are candidates for subsequents processing
processing_command 
    is triggered when no previous status exists or status is older than the file unless force option is used 
    recieves two parameters, the file name and the status file name
    is left the responsibility to update the status file name according to its own logic
    default processing_command is : echo

OPTIONS:
  -c: clear all status files from memory_directory before processing
  -f: forces processing when status file is newer than its corresponding file
  -h: display this help
      ignore any other options and parameters
  -t: trace mode
  -v: verbose mode, trace progress on standard error
  -p: purge mode, removes any status files in memory_directory which has no corresponding file
      no processing is made on files
EXAMPLE:
  typical use is in association with the find command which retrieves the list of files to process
  find . -path ./.mymemory -prune -o -type f -print | processMemory ./.mymemory ls
"
#-------------------------------------------------------------------------------
# definitions
#-------------------------------------------------------------------------------
readonly    ONGOING=".tmp"
readonly    IGNORE=".ignore"
readonly    DONE=".done"

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
# parse options
forceOption=0
verboseOption=0
purgeMode=0

while getopts ":c :f :h :p :t :v" opt; do
  case ${opt} in
    c)
      clearOption=1
      ;;
    f)
      forceOption=1
      ;;
    h)
      help
      exit 0
      ;;
    p)
      purgeMode=1
      ;;
    t)
      TRACE=on
      trace "trace mode"
      ;;
    v)
      (( verboseOption++ ))
      trace "trace verbose"
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

if [[ $# -lt 1 ]] ; then
    error "memory_directory parameter missing"
    exit 1
fi

memoryPath=${1}
if [[ ! -d "${memoryPath}" ]] ; then
    error "memory directory '${memoryPath}' does not exist or has restricted access rights"
    exit 1
fi

screenCount=0
newCount=0
ignoreCount=0
processCount=0
purgeCount=0

if (( purgeMode )) ; then
  set -x
  find "${memoryPath}" -type f -name "*${IGNORE}" -o -iname "*${DONE}" -o -iname "*${ONGOING}" |\
    (( screenCount++ ))
    while IFS= read fileToProcess ; do
      [[ ! -f "$(head -n 1 "${fileToProcess}" 2>/dev/null)" ]] && rm -f ${fileToProcess} && (( purgeCount++ ))
      (( verboseOption > 0 )) && printf "${screenCount} - ${purgeCount}\r" 1>&2
    done
  (( verboseOption > 0 )) && info "screen=${screenCount}; purge=${newCount}"
  exit
fi

if (( clearOption )) ; then
  rm -f ${memoryPath}${IGNORE} ${memoryPath}${DONE}  ${memoryPath}${ONGOING}
fi

readonly  DEFAULT_ACTION=echo

action=${@:2}
action=${action:-${DEFAULT_ACTION}}

while IFS= read -r fileToProcess ; do 
    (( screenCount++ ))
    proceedAction=0

    fileHash="${memoryPath}/$(echo ${fileToProcess} | md5sum | cut -f1 -d' ')"

    ignore=0; [[ -f "${fileHash}${IGNORE}" ]] && ignore=1
    done=0  ; [[ -f "${fileHash}${DONE}" ]]   && done=1
    
    # for unknown status (new file) : set status ongoing
    if (( ongoing = !ignore && !done )) ; then
      if echo "${fileToProcess}" > "${fileHash}${ONGOING}" ; then
        ((newCount++))
      else
        warning "cannot create status file ${fileHash}${ONGOING}"
        continue
      fi
    fi

    # determine if action can be applied
    if (( proceedAction = ongoing )) ; then
        fileStatus="${fileHash}${ONGOING}"
    elif (( done )) ; then
        fileIsNewer=0 ; [[ "${fileToProcess}" -nt "${fileHash}${DONE}" ]] && fileIsNewer=1
        if (( proceedAction = forceOption || fileIsNewer )) ; then
            fileStatus="${fileHash}${DONE}"
        fi
    fi

    if (( proceedAction )) ; then
        ${action} "${fileToProcess}" "${fileStatus}"
        ((processCount++))
        (( verboseOption == 1 )) && printf "${processCount}\r" 1>&2
        (( verboseOption > 1 )) && info process "${fileToProcess}" with status "${fileStatus}"
    else
        ((ignoreCount++))
    fi

    # for status ignore : do nothing 

done;

#(( verboseOption == 1 )) && echo 1>&2
(( verboseOption > 0 )) && info "screen=${screenCount} new=${newCount}; ignore=${ignoreCount}; process=${processCount}"
