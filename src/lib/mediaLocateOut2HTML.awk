#!/bin/awk -f

# ----------------------------------------------------------------------
# logs text in stderr when verbose mode is on
# verbose mode is activated by adding the following parameters "-v verbose=1"
#
function trace (text) { if (verbose) { print text > "/dev/stderr" } }

# ----------------------------------------------------------------------
# returns the URL encoded form of the string
#
function encodeURIComponent(str) {
  while (y++ < 125) z[sprintf("%c", y)] = y
  while (y = substr(str, ++j, 1))
    q = y ~ /[[:alnum:]_.!~*\/()-]/ ? q y : q sprintf("%%%02X", z[y])
  return q
}

# ----------------------------------------------------------------------
# returns file extention from the file name
#
function getFileExtention(fileName) {
  n = split(fileName, a, ".")
  return tolower(a[n])
}

# ----------------------------------------------------------------------
# returns a string representing the type of media based on file name extension
#
function getMediaType(fileName) {
  ext=getFileExtention(fileName)
  return mediaTypes[ext]
}

function makeThumbDir() {
  if (! mkThumbDir) {
    cmd=  "mkdir -p " thumbDir
    system(cmd)
    trace("cmdCR="cmdCR)
    close(cmd)
    mkThumbDir = 1
  }
}

function execCmd(cmd) {
  trace("cmd="cmd)
  cmdCR = system(cmd)
  trace("cmdCR="cmdCR)
  close(cmd)
  return cmdCR
}

BEGIN {
  mkThumbDir=0
  mediaShown=0
  mediaTypes["3gp"]="MOVIE"
  mediaTypes["avi"]="MOVIE"
  mediaTypes["mkv"]="MOVIE"
  mediaTypes["mov"]="MOVIE"
  mediaTypes["mp4"]="MOVIE"
  mediaTypes["mpeg"]="MOVIE"
  mediaTypes["mpg"]="MOVIE"
  mediaTypes["wmv"]="MOVIE"
  mediaTypes["webm"]="MOVIE"
  mediaTypes["gif"]="PICTURE"
  mediaTypes["jpeg"]="PICTURE"
  mediaTypes["jpg"]="PICTURE"
  mediaTypes["png"]="PICTURE"
  mediaTypes["tiff"]="PICTURE"
  mediaTypes["webp"]="PICTURE"
}

{
  latitude  = $1
  longitude = $2
  truePosition = (( latitude + longitude ) != 0)

  if ( truePosition ){

    trace("GPS="latitude","longitude)
    mediaFile = $3
    trace("mediaFile="mediaFile)
    ext=getFileExtention(mediaFile)
    mediaType = getMediaType(ext)
    trace("mediaType="mediaType)
    mediaToShow = 1

    mediaHash = $4
    mediaHashPath = ""
    if ( mediaHash == "" ){ 
      cmd = "echo -n \"" mediaFile "\" | md5sum | cut -f1 -d\" \""
      trace("cmd="cmd)
      cmd | getline mediaHash
      close(cmd)
      mediaHashPath = thumbDir "/"
    } else
    trace("mediaHash="mediaHash)

    mediaThumbnailFile  = mediaHashPath mediaHash ".jpg"
    mediaDocument       = mediaHashPath mediaHash ".html"
    mediaExifInfo       = mediaHashPath mediaHash "-exif.html"

    if (mediaType == "MOVIE"){
      makeThumbDir()
      infoText="video<br/>" ext
      execCmd("ffmpeg -hide_banner -v quiet -nostdin -i \"" mediaFile "\" -vf  thumbnail,scale=w=128:h=-1 -frames:v 1 " mediaThumbnailFile)
    } else if (mediaType == "PICTURE") {
      makeThumbDir()
      infoText="image<br/>" ext
      execCmd("convert -quiet -resize 128x \"" mediaFile "\" " mediaThumbnailFile)
    } else {
      mediaToShow = 0
    }

    if (mediaToShow == 1) {

      if (mediaShown == 0){
        mediaShown=1
          print "<!DOCTYPE html>"
          print " <html>"
          print "  <head>"
          print "   <style>"
          print "    img {"
          print "     max-width: 100%;"
          print "     max-height: 100%;"
          print "    }"
          print "    .overall {"
          print "     border: 1px solid green;"
          print "    }"
          print "    .parent {"
          print "     float: left;"
          print "    }"
          print "    .child {"
          print "     height: 75px;"
          print "     float: top;"
          print "     background-color: white;"
          print "     border: 1px solid red;"
          print "     text-align:center";
          print "    }"
          print "    .locations {"
          print "     border: 1px solid blue;"
          print "     text-align:center"
          print "    }"
          print "    .oms {"
          print "     display: inline-block;"
          print "     font-size: 10px;"
          print "     height: 32px;"
          print "     width: 32px;"
          print "     max-height:32px;"
          print "     background-repeat: no-repeat;"
          print "     background-position: center; "
          print "     background-image:url(data:image/jpg;base64,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);"
          print "    }"
          print "    .maps {"
          print "     display: inline-block;"
          print "     font-size: 10px;"
          print "     height: 32px;"
          print "     max-height:32px;"
          print "     width: 32px;"
          print "     background-repeat: no-repeat;"
          print "     background-position: center; "
          print "     background-image:url(data:image/jpg;base64,iVBORw0KGgoAAAANSUhEUgAAABYAAAAgCAYAAAAWl4iLAAABhWlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw1AUhU9TtSIVBTuIOGSoThbEijhKFYtgobQVWnUweekfNGlIUlwcBdeCgz+LVQcXZ10dXAVB8AfEydFJ0UVKvC8ptIjxweV9nPfO4b77AKFRYarZNQmommWk4jExm1sVA6/owSBVFDMSM/VEejEDz/V1Dx/f7yI8y/ven6tfyZsM8InEc0w3LOIN4plNS+e8TxxiJUkhPieeMKhB4keuyy6/cS46LPDMkJFJzROHiMViB8sdzEqGSjxNHFZUjfKFrMsK5y3OaqXGWn3yFwbz2kqa61SjiGMJCSQhQkYNZVRgIUK7RoqJFJ3HPPwjjj9JLplcZTByLKAKFZLjB/+D37M1C9EpNykYA7pfbPtjDAjsAs26bX8f23bzBPA/A1da219tALOfpNfbWvgIGNgGLq7bmrwHXO4Aw0+6ZEiO5KcSCgXg/Yy+KQcM3QJ9a+7cWuc4fQAyNKvlG+DgEBgvUva6x7t7O+f2753W/H4A1i9yzw0/Ky0AAAAJcEhZcwAACxMAAAsTAQCanBgAAAPmSURBVEjHpZVfaFtVHMc/59yb26a56Z8hcc3ade2YKMiYZbV7sCptQYaDDVZsXgayh4GOgrariO0UkW449EVQVJgbjuGgzar79zC6CrYMWTMVcVjrLFu71i5TzNKmbXJv7vWhaU3T3KTgeTvn9/1+7j2/8/udI3AY/o6ZYqAV2ANsB/yp0BTwc01J0UVNkX2DXfrDbH6xBtg+40LQCbwJeLOZfG4tscGtacAscAI4MdilJxzB/o6ZTcB54GmnnZRqSnKj7pYZ3h+BvYNd+uQa8KMdMxUKDANVTtAiRZqVxUVSCGSW8ATQMNilTwBLgnBTnevGrdd6Dy5Mb3KCuqRI+r1uxQEKsBnob+yZ01bAwOtu449dh3/vULqjvyYzHVJgV+iFqFIIco9a4A0AEW6q04FJoHQpZjPsPxJ/xfd8gZJSV+qFpkdTF1NTPRd50Xf1n4T3bLUEWv6DLqX9mekPC3rv9ZqbbdMu1dRrHk2tx1K9LgMvsAMYyAZNlN00Et6zZUCrCDfV9QP7sgmny3ZffnV7+97rb5euSk/j8ZjEsi8Bu5fXkkWTyVj5UQm2AC6JcFPdOFCdCVVqDMv97IOtRQem7mT7aGPPXBVwB8DSIlas4qhti+hy9u5JoHJN15RZSX3PxOhzH2WHAgx26XeBW7YSt+bLPyYNCuCXaZWRqivb1l+aQnqixshInhoQ1uLCxjOWpY5llqCUQCx9xbP/galu+EsBnjAGVMcKaOyZcy/6rmwzC4fULOG4BG4vzwpfiJpa9ZQrNdWAdifw7JbOtoTeW+wQvi2B7wFctQuG+6lxJUPwjjGgthkD6kpjGFdVcbK/8RBK+FiOJIVEuKnuRaXK/MbbOiqEYji16zjwLcDfycqGQ5EdW6dtqeQAt6gYxhV978SkUIwtOYQ1QE3c9iaPRZ8kD/Q+2Bel77ufbOmJvpfn/LFQ7E+j9fb1pKbkkR4PBc4nlrd+CriRS30htss4Z3jUPNBfEHyycru5mk0bOADMZz2JxVrz/YVHtDxQA3g51Bo00q9NXM3mGHA4U33X2GYemavIt32At0KB4M2VDlnVdJdLTgOfL88jyXKrM/q4jJP3Hu4XcflBzsfUGFALgKG4rdd2RxoYzn9YvwE7Q4Hg3KqeXvMENZtxoOXkbH1kHdB5YF8mNCs4BZ84k9APriOvbaFAcDRbQDpeXLa4AHyZA/q1LcQXjv5cv7Pz3P4SYAzwZYSiwGOhQPC+k1fmAocCwYdAd5bQu7mgecEAQohTwJ9pSxEQn+Xz5QWPtPaZwOm0pa9Cgb7Y/wanRl96M6zHoK5HJOEHC4aAYgt5bT2efwF8o0pQXKA0iAAAAABJRU5ErkJggg==);"
          print "    }"
          print "   </style>"
          print "  </head>"
          print " <body>"
          print "  <div class=\"overall\">"
      }

      key = longitude latitude;
      media[key] = mediaHash;
      url_openstreetmap = "https://www.openstreetmap.org/#map=<zoom>/<latitude>/<longitude>"

      #execCmd("curl -s \"https://nominatim.openstreetmap.org/ui/reverse?format=html&lat=" latitude "&lon=" longitude "&zoom=18\" >" openStreetMapInfo)
      print "   <div class=\"parent container\" id=" mediaHash ">"
      print "    <a href=\"" mediaFile "\" target=_blank>"
      print "     <div class=child><img src=\"" thumbnailMediaFile "\"/></div>"
      print "    </a>"
      print "    <div class=\"locations\">"
      print "     <a href=\" https://nominatim.openstreetmap.org/ui/reverse.html?lat=" latitude "&lon=" longitude "&zoom=18\" target=_blank>"
      #    if (exifdump == "true"){
      #      execCmd("exiftool -h " mediaFile " > " exifInfo)
      #      print "     <div class=\"oms\">" infoText "</div>"
      #    }
      print "      <div class=\"oms\">" infoText "</div>"
      print "     </a>"
      print "     <a href=\"https://www.google.fr/maps?&q=" latitude "," longitude "&z=17\" target=_blank>"
      print "      <div class=\"maps\">" infoText "</div>"
      print "     </a>"
      print "    </div>"
      print "   </div>"
    }
  }
}

END{

  if (mediaShown == 1){
    print "  </div>"
    print " </body>"
    print "</html>"
  } 

# print "unsorted"
#  for (key in media) {
#    print key " : " media[key]
#  }

#  n = asorti(media, sorted)
#  print "sorted"
#  for (i = 1; i <= n; i++) {
#    print sorted[i] " : " media[sorted[i]]
#  }

}
