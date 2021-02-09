#!/bin/bash
#
# Purpose: Similar to HVC, but with blue water and with colours more indicative of
#          land temperatures.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_hvct.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" -e "HVCT" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
