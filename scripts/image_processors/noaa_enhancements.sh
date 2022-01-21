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
#   4. Enhancement
#
# Example:
#   ./noaa_mcir.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3
ENHANCEMENT=$4

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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "${ENHANCEMENT}" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
