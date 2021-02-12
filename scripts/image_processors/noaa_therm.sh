#!/bin/bash
#
# Purpose: Produces a false colour image from NOAA APT images based on temperature.
#          Provides a good way of visualising cloud temperatures. The palette used
#          can be changed using the -P option.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_therm.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" -e "therm" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
