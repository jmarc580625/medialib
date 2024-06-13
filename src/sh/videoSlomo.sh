#!/bin/bash
videoIn=$1

case ${2} in
	4)
		slow=4
		filter="[0:v]setpts=4.0*PTS[vid];[0:a]atempo=0.5,atempo=0.5[a];[vid]minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=120'[v]"
		;;
	*)
		slow=2
		filter="[0:v]setpts=2.0*PTS[vid];[0:a]atempo=0.5[a];[vid]minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=120'[v]"
		;;
esac
videoOut=${1%.*}_slomo${slow}.mp4

set -x
ffmpeg 	\
	-i ${videoIn} \
	-filter_complex "${filter}" \
	-map "[v]" -map "[a]" \
	${videoOut} 2>/dev/null
set +x
