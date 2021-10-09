#!/bin/bash
#
# Purpose: The NOAA JF enhancement is a hybrid enhancement scheme used to highlight both sea 
#	   surface temperatures, and cold cloud tops associated with thunderstorms and other weather systems. 
#	   It is somewhat simpler to interpret than the later JJ enhancement. The coldest portion 
#	   of the enhancement (less than -33C) is nearly identical to the general-use MB enhancement. 
#	   Maximum enhancement is pro- vided at the warm end (25 to 10C) to depict sea surface temperatures 
#	   and warm low clouds in tropical and sub-tropical areas. This enhancement option is temper- ature normalised.
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "JF" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
