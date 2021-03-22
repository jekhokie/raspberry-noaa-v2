#!/bin/bash
#
# Purpose: Color the NOAA sensor 4 IR image using a map to colour the sea blue and land
#          green. High clouds appear white, lower clouds gray or land/sea coloured, clouds
#          generally appear lighter, but distinguishing between land/sea and low cloud may
#          be difficult. Darker colours indicate warmer regions.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_mcir.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2

# note that this is replaced in place so overwrite of fixed file
OUTPUT_IMAGE="/srv/images/RollingAnimation.avi"


# calculate any extra args for the processor
extra_args=""
if [ "${NOAA_CROP_TELEMETRY}" == "true" ]; then
  extra_args="-c"
fi

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "MCIR" "${INPUT_WAV}" "${OUTPUT_IMAGE}"

# convert updated AVI to web-display ready mp4
ffmpeg -i ${OUTPUT_IMAGE} -c:v libx264 -c:a copy -y /srv/images/RollingAnimation.mp4
