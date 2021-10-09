#!/bin/bash
#
#
# Purpose: The NOAA HE enhancement is used principally by weather offices in the western United States. 
#	   It provides good enhancement of a wide variety of cloud types, but is somewhat complex, and 
#	   may be difficult to use at first. It enhances low and middle level clouds common along the 
#    	   Pacific Coast of North America in two sep- arate gray shade ranges. The freezing level is easily 
#	   determined, an advantage for aviation users concerned with icing. Step wedge regions display very 
#	   cold infrared cloud top temperatures associated with thunderstorms and frontal systems in 5 degree 
#	   increments down to -60 C. Two additional repeat gray segments define cloud top temperatures colder 
#	   than -60C. This enhancement option is tem- perature normalised.
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "HE" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
