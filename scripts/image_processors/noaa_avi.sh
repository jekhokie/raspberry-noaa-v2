#!/bin/bash
#
# Purpose: Generate a slide show mp4 video of NOAA images.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#
# Example:
#   ./noaa_avi.sh /path/to/map_overlay.png /path/to/input.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2

# note that this is replaced in place to overwrite fixed file
OUTPUT_IMAGE="${NOAA_HOME}/tmp/RollingAnimation.avi"

# calculate any extra args for the processor
extra_args=""
if [ "${NOAA_CROP_TELEMETRY}" == "true" ]; then
  extra_args=${extra_args}" -c"
fi

if [ "${NOAA_CROP_TOPTOBOTTOM}" == "false" ]; then
  extra_args=${extra_args}" -A"
fi

if [ "${NOAA_INTERPOLATE}" == "true" ]; then
  extra_args=${extra_args}" -I"
fi

# produce the output image
$WXTOIMG -o -M 49 -m "${MAP_OVERLAY}" ${extra_args} -e "MCIR" "${INPUT_WAV}" "${OUTPUT_IMAGE}"

# convert updated AVI to web-display ready mp4
# ffmpeg -i ${OUTPUT_IMAGE} -c:v libx264 -c:a copy -y /srv/images/RollingAnimation.mp4
$FFMPEG -hide_banner -loglevel error -an -i ${OUTPUT_IMAGE} -vcodec libvpx-vp9 -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -y ${NOAA_ANIMATION_OUTPUT}
