#!/bin/bash
#
# Purpose: Creates a false colour image from NOAA APT images based on sea surface tem- perature. 
# 	   Uses the sea surface temperature derived from just the sensor 4 image to colour the image. 
# 	   Land appears black and cold high cloud will also appear black. The sea surface temperature 
#	   may be incorrect due to the presence of low cloud, or of thin or small clouds in the pixel 
#	   evaluated, or from noise in the signal. The palette used can be changed using the -P option.
#
# Input parameters:
#   1. Map overlap file
#   2. Input .wav file
#   3. Output .jpg file
#
# Example:
#   ./noaa_msa.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "sea" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
