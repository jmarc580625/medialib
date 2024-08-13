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
generates a html output into an 'mediaLocate.html' file
  -d: restricts processed file in the curent directory
  -f: forces processing when status file is newer than its corresponding file
  -h: display this help
      Ignore any other option and parameter
  -o: redirect output to the specified outfile
      default output is 'mediaLocate.html'
      uses '-' to direct output to standard directory
  -r: refresh mediaLocate.html
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

# returns file extention from the file name
#
function getFileExtention { e=${1##*.} ; echo ${e,,} ; }

# returns a string representing the type of media based on file name extension
#
declare -x MEDIALOCATE_IS_MOVIE="video"
declare -x MEDIALOCATE_IS_PICTURE="image"
declare -A mediaTypes
  mediaTypes["3gp"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["avi"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["mkv"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["mov"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["mp4"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["mpeg"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["mpg"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["wmv"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["webm"]=${MEDIALOCATE_IS_MOVIE}
  mediaTypes["gif"]=${MEDIALOCATE_IS_PICTURE}
  mediaTypes["jpeg"]=${MEDIALOCATE_IS_PICTURE}
  mediaTypes["jpg"]=${MEDIALOCATE_IS_PICTURE}
  mediaTypes["png"]=${MEDIALOCATE_IS_PICTURE}
  mediaTypes["tiff"]=${MEDIALOCATE_IS_PICTURE}
  mediaTypes["webp"]=${MEDIALOCATE_IS_PICTURE}

[[ "$(declare -p ${mediaTypes})" =~ "declare -A" ]] && export MEDIALOCATE_TYPES=$(declare -p mediaTypes)

function setFindFilter {
  declare -n filter=$1
  for type in "${!mediaTypes[@]}" ; do
    a+=("-o")
    a+=("-iname")
    a+=("\\*.${type}")
  done
  filter+=("\\(")
  filter+=("${a[@]:1}")
  filter+=("\\)")
  #( "\(" -iname "\*.jpg" -o -iname "\*.jpeg" -o -iname "\*.png" -o -iname "\*.mp4" -o -iname "\*.3gp" -o -iname "\*.avi" -o -iname "\*.mov" "\)" )
} 

# generates and stores html elements for a geotaged media file 
#
function mediaLocateCreateHtmlDiv {
  IFS=';' read -ra mediaInfo <<< "$@"

  local -n latitude=mediaInfo[0]  ; traceVar latitude
  local -n longitude=mediaInfo[1] ; traceVar longitude
  local -n mediaFile=mediaInfo[2] ; traceVar mediaFile
  local -n mediaHash=mediaInfo[3] ; traceVar mediaHash
  local -n thumbDir=mediaInfo[4]  ; traceVar thumbDir
  local mediaFileURL=$(echo ${mediaFile} | sed -e "s/'/\&apos;/g") ; traceVar mediaFile

  if [[ $(bc <<<"( ${latitude} + ${longitude}) != 0") == 1 ]] ; then

    [[ ${MEDIALOCATE_TYPES} =~ ^declare ]] && eval ${MEDIALOCATE_TYPES}

    mediaExt=${mediaFile##*.}             ; traceVar mediaExt
    mediaType=${mediaTypes[${mediaExt}]}  ; traceVar mediaType
    mediaToShow=1

    thumbnailMediaFile="${thumbDir}/${mediaHash}.jpg" ; traceVar thumbnailMediaFile
    mediaDivFile="${thumbDir}/${mediaHash}.html"      ; traceVar mediaDivFile

    if [[ "${mediaType}"  == "${MEDIALOCATE_IS_MOVIE}" ]] ; then
      ffmpeg -hide_banner -v quiet -nostdin -i "${mediaFile}" -vf  thumbnail,scale=w=128:h=-1 -frames:v 1 "${thumbnailMediaFile}"
    elif [[ "${mediaType}"  == "${MEDIALOCATE_IS_PICTURE}" ]] ; then 
      convert -quiet -resize 128x "${mediaFile}"  "${thumbnailMediaFile}"
    else 
      mediaToShow=0
    fi

    traceVar mediaToShow

    if (( mediaToShow )) ; then
      #trace "**** genetating media html div"

      mediaShown=1
      cat > ${mediaDivFile} <<EOT
    <data class="json-media" value='
      {
        "id":"${mediaHash}",
        "mediasource":"${mediaFileURL}",
        "mediathumbnail":"${thumbnailMediaFile}",
        "mediatype":"${mediaType}",
        "mediaformat":"${mediaExt}",
        "latitude":"${latitude}",
        "longitude":"${longitude}"
      } 
    '></data>
EOT
    fi

  fi

}; export -f mediaLocateCreateHtmlDiv

# groups html div into a global html page
#
function htmlMediaRendering {
  outFile=$1
  thumbDir=$2
  outDiv=${thumbDir}/$$.div

  cat ${thumbDir}/*.html > ${outDiv} 2>/dev/null

  if [[ ! -s ${outDiv} ]] ; then
    rm -f ${outDiv}
    return 1
  fi

  cat > ${outFile} <<EOT1
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <link rel="stylesheet" href="${thumbDir}/mediaLocate.css">
    <script src="${thumbDir}/nav.js"></script>
    <script src="${thumbDir}/content.js"></script>
    <script src="${thumbDir}/mapsetup.js"></script>
  </head>
  <body>
    <div>
      <div>
        <template>
          <div class="parent container" id="">
            <a class="media" href="" target=_blank>
                <img class="child" data-src="" src=""/>
            </a>
            <div class="locations">
              <a class="oms" href="" target=_blank></a>
              <a class="maps" href="" target=_blank></a>
            </div>
          </div>
        </template>
      </div>
      <div>
EOT1

  cat ${outDiv} >> ${outFile}
  rm -f ${outDiv}

  cat >> ${outFile} <<EOT2
      </div>
    </div>
    <div class="overall left" style="overflow-y:scroll"></div>
    <div class="right" id="map"></div>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        function loadImagesLazily() {
          let images = document.querySelectorAll("img[data-src]");
          console.log('remaining lazy load: '+images.length);
          for (let i = 0; i < images.length; i++) {
            let rect = images[i].getBoundingClientRect();
            if (images[i].hasAttribute("data-src")
              && rect.bottom > 0 && rect.top < window.innerHeight
              && rect.right > 0 && rect.left < window.innerWidth) {
              images[i].setAttribute("src", images[i].getAttribute("data-src"));
              images[i].removeAttribute("data-src");
            }
          }
        };

        let viewport = document.getElementsByClassName('left')[0];
        viewport.addEventListener('scroll', loadImagesLazily);
        viewport.addEventListener('resize', loadImagesLazily);
        loadImagesLazily();
      });

      gpsOrigin = {latitude:0, longitude:0};
      gpsNotreDameDeParis = {latitude:48.853,longitude:2.35};
      GPSRef = gpsOrigin;

      console.time('initializeMap');
      initializeMap();
      var marker = L.marker([gpsNotreDameDeParis.latitude, gpsNotreDameDeParis.longitude]).addTo(map);
      marker._icon.classList.add("markerOrigin");
      map.setView(new L.LatLng(gpsNotreDameDeParis.latitude, gpsNotreDameDeParis.longitude), 5);
      console.timeEnd('initializeMap');

      console.time('initializeContent');
      initializeContent(
        document.getElementsByClassName('left')[0],
        document.getElementsByTagName("template")[0],
        "json-media",
        gpsOrigin
      );
      console.timeEnd("initializeContent");

    </script>
  </body>
</html>
EOT2

  cp -f ${LIB_DIR}/mediaLocate.css ${thumbDir}
  cp -f ${LIB_DIR}/nav.js ${thumbDir}
  cp -f ${LIB_DIR}/content.js ${thumbDir}
  cp -f ${LIB_DIR}/mapsetup.js ${thumbDir}

  return 0

}

# extracts geo tag information from media file and updates associated status file 
#
function processMedia {
 
  local -r readonly STATUS_NEW=".tmp"
  local -r STATUS_DONE=".done" 
  local -r STATUS_IGNORE=".ignore"

  local fileToProcess=$1
  local fileCurentStatus=$2 ${str%/*}
  local fileHash=${fileCurentStatus%.*}
  local hashDirname=${fileCurentStatus%/*}
  local hashBaseName="${fileCurentStatus##*/}"
  local hash=${hashBaseName%.*}
  local fileStatus=${fileCurentStatus##*.}

  local statusIsNew=0   ; [[ ".${fileStatus}" == "${STATUS_NEW}" ]]  && statusIsNew=1
  local statusIsDone=0  ; [[ ".${fileStatus}" == "${STATUS_DONE}" ]] && statusIsDone=1

  local exiftoolScript="${LIB_DIR}/mediaLocateFindGPS" ; traceVar exiftoolScript
  
  local gpsData=$(exiftool -n -p "${exiftoolScript}" "${fileToProcess}" 2>/dev/null)
  if [[ -n "${gpsData}" ]] ; then
    mediaLocateCreateHtmlDiv $(echo "${gpsData};${hash};${hashDirname}" | tr -d '\r')
    (( statusIsNew )) && mv -f "${fileCurentStatus}" "${fileHash}${STATUS_DONE}" #>/dev/null 2>&1
    touch "${fileHash}${STATUS_DONE}" #>/dev/null 2>&1
  else
    mv -f "${fileCurentStatus}" "${fileHash}${STATUS_IGNORE}" #>/dev/null 2>&1
  fi
} ; export -f processMedia

function _proc_media {
  echo  params: ${@} >&2
  declare -p mediaTypes >&2
  echo PID=$$ >&2
} ; export -f _proc_media


#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------
declare   forceMode=""
declare   refreshMode=0
declare   purgeMode=0
declare   newerOption=""
declare   maxDepthSearch=""
declare   memoryPath=./.mediaLocate
declare   outputFile="mediaLocate.html"
declare   outputTempFile="$$.tmp.htm" 
declare   outputSpec="cat > ${outputTempFile}"
declare   outToStdout=0
#readonly  FindNameFilter=( "\(" -iname "\*.jpg" -o -iname "\*.jpeg" -o -iname "\*.png" -o -iname "\*.mp4" -o -iname "\*.3gp" -o -iname "\*.avi" -o -iname "\*.mov" "\)" )
declare -a FindNameFilter
setFindFilter FindNameFilter

# parse options
while getopts ":d :f :h :o: :p :r :t :v" opt; do
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
    p)
      purgeMode=1
      ;;
    r)
      refreshMode=1
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

mkdir -p "${memoryPath}"

[[ -f "${outputFile}" && (( ! forceOption )) ]] && newerOption="-newer ${outputFile}"

if (( purgeMode )) ; then
  ${EXEC_HOME}/processMemory ${verboseOption} -p "${memoryPath}"
  exit
fi

if (( ! outToStdout )) ; then
  outputTempFile="${memoryPath}/${outputTempFile}"
  outputSpec="cat > ${outputTempFile}"
fi

awkScript="${LIB_DIR}/mediaLocateOut2HTML2"    ; traceVar awkScript

if (( ! refreshMode )) ; then
  eval stdbuf -oL find . -path "${memoryPath}" -prune -o -type f ${newerOption} ${FindNameFilter[@]} ${maxDepthSearch} -print  |\
    ${EXEC_HOME}/processMemory ${verboseOption} ${forceOption} "${memoryPath}" ${options} processMedia
fi

htmlMediaRendering ${outputFile} ${memoryPath}
