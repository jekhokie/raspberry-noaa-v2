#!/bin/bash
#
# Purpose: Color the NOAA sensor 4 IR image using a map to colour the sea blue and land
#          green. High clouds appear white, lower clouds gray or land/sea coloured, clouds
#          generally appear lighter, but distinguishing between land/sea and low cloud may
#          be difficult. Darker colours indicate warmer regions. Coloring for precipitation.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_mcir_precip.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" -e "MCIR-precip" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
