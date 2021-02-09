#!/bin/bash
#
# Purpose: Creates a false colour image from NOAA APT images based on temperature using
#          the HVC colour model. Uses the temperature derived from the sensor 4 image to
#          select the hue and the brightness from the histogram equalised other image to
#          select the value and chroma. The HVC colour model attempts to ensure that different
#          colours at the same value will appear to the eye to be the same brightness
#          and the spacing between colours representing each degree will appear to the eye to
#          be similar. Bright areas are completely unsaturated in this model. The palette
#          used can be changed using the -P option. Precipitation is colored.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_hvc_precip.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
MAP_OVERLAY=$1
INPUT_WAV=$2
OUTPUT_IMAGE=$3

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" -e "HVC-precip" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
