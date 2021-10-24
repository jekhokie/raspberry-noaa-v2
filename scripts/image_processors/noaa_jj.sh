#!/bin/bash
#
# Purpose: The NOAA JJ enhancement is used to highlight both sea surface temperatures, and cold cloud 
# 	   tops associated with thunderstorms and other weather systems. Maxi- mum enhancement is 
# 	   provided at the warm end (23 to 0C) to depict sea surface temperatures and low clouds. 
#	   The presence of a freezing level break point is important for aviation users interested in 
#	   icing conditions. Multiple, steep, ramp enhancement ranges provide considerable detail within 
#	   cold cloud tops such as thunderstorms, but it is difficult to determine the actual temperatures 
# 	   with any accuracy. This enhancement option is temperature normalised.
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "JJ" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
