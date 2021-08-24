#!/bin/bash
#
# Purpose: Similar to HVC, but with blue water and with colours more indicative of
#          land temperatures. Colors for precipitation.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_hvct_precip.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3

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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "HVCT-precip" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
