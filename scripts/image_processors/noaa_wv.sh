#!/bin/bash
#
# Purpose : The modified NOAA WV curve is used for the 6.7 micron water vapor channel (CH3) on GOES. 
#	    The only temperature range that is enhanced is between -5C and -90C. 
#	    Temperatures colder than -90C are shown as white, and temperatures warmer than -5C are displayed as black. 
# 	    This enhancement option is temperature normalised. (See also WV-old).
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "WV" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
