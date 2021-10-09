#!/bin/bash
#
# Purpose: The NOAA HF enhancement is the most current of the H series of enhance- ments, and 
#	   is used principally by weather offices in the western United States. It provides good 
#	   enhancement of low and middle level clouds common along the Pacific Coast of North America. 
#	   Step wedge regions display very cold infrared cloud top temperatures associated with 
#   	   thunderstorms and frontal systems in 5 degree increments down to -60 C. Two additional 
#	   repeat gray segments define cloud top temperatures colder than -60C. This enhancement 
#	   option is temperature normalised.
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "HF" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
