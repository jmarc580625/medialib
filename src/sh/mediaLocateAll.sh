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

# arc cosinus function
#
declare -x MEDIALOCATE_LATITUDE_REF=48.853
declare -x MEDIALOCATE_LONGITUDE_REF=2.35

function arccos {
    scale=3
    if (( $(bc -l <<<"$1 == 0") )); then
        bc -l <<<"a(1)*2"
    elif (( $(bc -l <<<"(-1 <= $1) && ($1 < 0)") )); then
        bc -l <<<"scale=${scale}; a(1)*4 - a(sqrt((1/($1^2))-1))"
    elif (( $(bc -l <<<"(0 < $1) && ($1 <= 1)") )); then
        bc -l <<<"scale=${scale}; a(sqrt((1/($1^2))-1))"
    else
        echo "input out of range" >&2
        return 1
    fi
} ; export -f arccos

# compute distance between two gps points
#
function getDistanceBetweenGPSPoints  {
  r1=$( bc -l <<<"s($1)*s($3)+c($1)*c($3)*c($4-$2)")
  r2=$(arccos $r1)
  bc -l <<<"6371 * $r2"
} ; export -f getDistanceBetweenGPSPoints

# generates and stores html elements for a geotaged media file 
#
function mediaLocateCreateHtmlDiv {
  IFS=';' read -ra mediaInfo <<< "$@"

  local -n latitude=mediaInfo[0]  ; traceVar latitude
  local -n longitude=mediaInfo[1] ; traceVar longitude
  local -n mediaFile=mediaInfo[2] ; traceVar mediaFile
  local -n mediaHash=mediaInfo[3] ; traceVar mediaHash
  local -n thumbDir=mediaInfo[4]  ; traceVar thumbDir

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
      distance=$(getDistanceBetweenGPSPoints ${MEDIALOCATE_LATITUDE_REF} ${MEDIALOCATE_LONGITUDE_REF} ${latitude} ${longitude})

      mediaShown=1
      cat > ${mediaDivFile} <<EOT
    <div class="parent container" id="${mediaHash}" data-distance="${distance}" data-latitude="${latitude}" data-longitude="${longitude}">
      <a href="${mediaFile}" target=_blank>
        <div class=child><img src="${thumbnailMediaFile}"/></div>
      </a>
      <div class="locations">
        <a href="https://nominatim.openstreetmap.org/ui/reverse.html?lat=${latitude}&lon=${longitude}&zoom=18" target=_blank>
          <div class="oms"> ${mediaType}<br/>${mediaExt}" </div>
        </a>"
        <a href="https://www.google.fr/maps?&q=${latitude},${longitude}&z=17" target=_blank>
          <div class="maps"> ${mediaType}<br/>${mediaExt}" </div>
        </a>
      </div>
    </div>
EOT
    fi

  fi
set +x
}
export -f mediaLocateCreateHtmlDiv

# groups html div into a global html page
#
function htmlMediaRendering {
  outFile=$1
  thumbDir=$2
  outDiv=${thumbDir}/$$.div

  cat ${thumbDir}/*.html > ${outDiv}

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
    <script>
      var myMarkers =[];
      function initialize() {
        map = L.map('map');
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
          maxZoom: 18,
          attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery Â© <a href="http://cloudmade.com">CloudMade</a>'
        }).addTo(map);
        map.setView(new L.LatLng(48.853, 2.35), 18);
        // map.locate({setView: true, maxZoom: 8});    
      } 
      function findAncestor (el, cls) {
        while ((el = el.parentNode) && el.className.indexOf(cls) < 0);
        return el;
      } 
      function onMedia (latitude, longitude, key) {
        //console.log('latitude:'+latitude+'; longitude:'+longitude+'; key:'+key);
        map.panTo(new L.LatLng(latitude, longitude));
        myMarkers[key]._icon.classList.add("markerFocus");
      } 
      function outMedia (latitude, longitude, key) {
        //console.log('latitude:'+latitude+'; longitude:'+longitude+'; key:'+key);
        myMarkers[key]._icon.classList.remove("markerFocus");
      } 
      function onMarker(e) {   
        //console.log('in element key: '+this.key);
        var element = document.getElementById(this.key);
        //console.log('in element: '+element);
        var bd = element.style.borderWidth;
        element.style.borderWidth = "20px";
        element.style.borderColor = "solid black";
        console.log('border: '+bd);
        this._icon.classList.add("markerFocus");
        element.classList.add("mediaFocus");
        element.scrollIntoView({behavior: "smooth", block: "nearest"});

      } 
      function outMarker(e) {   
        this._icon.classList.remove("markerFocus");
        var element = document.getElementById(this.key);
        //console.log('out element.id: '+this.key);
        element.classList.remove("mediaFocus");
      } 
    </script>
    <style>
      img.markerOrigin { filter: hue-rotate(120deg); }
      img.markerFocus { filter: hue-rotate(260deg); }
      div.mediaFocus{ background-color: greenyellow;} 
      .left {
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 50%;
      } 
      #map,
      .right {
        position: absolute;
        left: 50%;
        top: 0;
        bottom: 0;
        right: 0; 
      }
      img {
        max-width: 100%;
        max-height: 100%;
      }
      .overall {
        border: 1px solid green;
      }
      .parent {
        float: left;
      }
      .child {
        height: 75px;
        float: top;
        background-color: white;
        border: 1px solid red;
        text-align: center;
      }
      .locations {
        border: 1px solid blue;
        text-align: center
      }
      .oms {
        display: inline-block;
        font-size: 10px;
        height: 32px;
        width: 32px;
        max-height:32px;
        background-repeat: no-repeat;
        background-position: center;
        background-image:url(data:image/jpg;base64,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);
      }
      .maps {
        display: inline-block;
        font-size: 10px;
        height: 32px;
        max-height:32px;
        width: 32px;
        background-repeat: no-repeat;
        background-position: center;
        background-image:url(data:image/jpg;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAgCAYAAAAWl4iLAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw1AUhU9TtSIVBTuIOGSoThbEijhKFYtgobQVWnUweekfNGlIUlwcBdeCgz+LVQcXZ10dXAVB8AfEydFJ0UVKvC8ptIjxweV9nPfO4b77AKFRYarZNQmommWk4jExm1sVA6/owSBVFDMSM/VEejEDz/V1Dx/f7yI8y/ven6tfyZsM8InEc0w3LOIN4plNS+e8TxxiJUkhPieeMKhB4keuyy6/cS46LPDMkJFJzROHiMViB8sdzEqGSjxNHFZUjfKFrMsK5y3OaqXGWn3yFwbz2kqa61SjiGMJCSQhQkYNZVRgIUK7RoqJFJ3HPPwjjj9JLplcZTByLKAKFZLjB/+D37M1C9EpNykYA7pfbPtjDAjsAs26bX8f23bzBPA/A1da219tALOfpNfbWvgIGNgGLq7bmrwHXO4Aw0+6ZEiO5KcSCgXg/Yy+KQcM3QJ9a+7cWuc4fQAyNKvlG+DgEBgvUva6x7t7O+f2753W/H4A1i9yzw0/Ky0AAAAJcEhZcwAACxMAAAsTAQCanBgAAAPmSURBVEjHpZVfaFtVHMc/59yb26a56Z8hcc3ade2YKMiYZbV7sCptQYaDDVZsXgayh4GOgrariO0UkW449EVQVJgbjuGgzar79zC6CrYMWTMVcVjrLFu71i5TzNKmbXJv7vWhaU3T3KTgeTvn9/1+7j2/8/udI3AY/o6ZYqAV2ANsB/yp0BTwc01J0UVNkX2DXfrDbH6xBtg+40LQCbwJeLOZfG4tscGtacAscAI4MdilJxzB/o6ZTcB54GmnnZRqSnKj7pYZ3h+BvYNd+uQa8KMdMxUKDANVTtAiRZqVxUVSCGSW8ATQMNilTwBLgnBTnevGrdd6Dy5Mb3KCuqRI+r1uxQEKsBnob+yZ01bAwOtu449dh3/vULqjvyYzHVJgV+iFqFIIco9a4A0AEW6q04FJoHQpZjPsPxJ/xfd8gZJSV+qFpkdTF1NTPRd50Xf1n4T3bLUEWv6DLqX9mekPC3rv9ZqbbdMu1dRrHk2tx1K9LgMvsAMYyAZNlN00Et6zZUCrCDfV9QP7sgmny3ZffnV7+97rb5euSk/j8ZjEsi8Bu5fXkkWTyVj5UQm2AC6JcFPdOFCdCVVqDMv97IOtRQem7mT7aGPPXBVwB8DSIlas4qhti+hy9u5JoHJN15RZSX3PxOhzH2WHAgx26XeBW7YSt+bLPyYNCuCXaZWRqivb1l+aQnqixshInhoQ1uLCxjOWpY5llqCUQCx9xbP/galu+EsBnjAGVMcKaOyZcy/6rmwzC4fULOG4BG4vzwpfiJpa9ZQrNdWAdifw7JbOtoTeW+wQvi2B7wFctQuG+6lxJUPwjjGgthkD6kpjGFdVcbK/8RBK+FiOJIVEuKnuRaXK/MbbOiqEYji16zjwLcDfycqGQ5EdW6dtqeQAt6gYxhV978SkUIwtOYQ1QE3c9iaPRZ8kD/Q+2Bel77ufbOmJvpfn/LFQ7E+j9fb1pKbkkR4PBc4nlrd+CriRS30htss4Z3jUPNBfEHyycru5mk0bOADMZz2JxVrz/YVHtDxQA3g51Bo00q9NXM3mGHA4U33X2GYemavIt32At0KB4M2VDlnVdJdLTgOfL88jyXKrM/q4jJP3Hu4XcflBzsfUGFALgKG4rdd2RxoYzn9YvwE7Q4Hg3KqeXvMENZtxoOXkbH1kHdB5YF8mNCs4BZ84k9APriOvbaFAcDRbQDpeXLa4AHyZA/q1LcQXjv5cv7Pz3P4SYAzwZYSiwGOhQPC+k1fmAocCwYdAd5bQu7mgecEAQohTwJ9pSxEQn+Xz5QWPtPaZwOm0pa9Cgb7Y/wanRl96M6zHoK5HJOEHC4aAYgt5bT2efwF8o0pQXKA0iAAAAABJRU5ErkJggg==);
      }
    </style>
  </head>
  <body>
    <div class="overall left" style="overflow-y:scroll">
EOT1

  cat ${outDiv} >> ${outFile}
  rm -f ${outDiv}

  cat >> ${outFile} <<EOT2
    </div>
    <div class="map right" id="map"></div>
    <script>
      initialize();
      x=48.853; y = 2.35; // Notre Dame de Paris
      var marker = L.marker([x, y]).addTo(map);
      marker._icon.classList.add("markerOrigin");
      map.setView(new L.LatLng(x, y), 13);

      var elements = document.getElementsByClassName('parent')
      for (var i = 0; i < elements.length; i++) {
        var latitude = elements[i].getAttribute("data-latitude");
        var longitude = elements[i].getAttribute("data-longitude");
        var key = elements[i].getAttribute("id");
        //console.log('marker @ latitude:'+latitude+'; longitude:'+longitude);
        var marker = L.marker([latitude, longitude]).addTo(map);
        marker.on('mouseover', onMarker);
        marker.on('mouseout', outMarker);
        marker.key = key;
        myMarkers[key] =  marker;
      }

      var elements = document.getElementsByClassName('child')
      for (var i = 0; i < elements.length; i++) {
        elements[i].addEventListener('mouseover', function (event) {
          var element = findAncestor(event.target, "parent");
          var latitude = element.getAttribute("data-latitude");
          var longitude = element.getAttribute("data-longitude");
          var key = element.getAttribute("id");
          onMedia(latitude, longitude, key);
        })
        elements[i].addEventListener('mouseout', function (event) {
          var element = findAncestor(event.target, "parent");
          var latitude = element.getAttribute("data-latitude");
          var longitude = element.getAttribute("data-longitude");
          var key = element.getAttribute("id");
          outMedia(latitude, longitude, key);
        })
      } 
    </script>
  </body>
</html>
EOT2

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
[[ -f "${outputFile}" ]] && newerOption="-newer ${outputFile}"


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
