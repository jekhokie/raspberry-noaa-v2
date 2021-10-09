#!/bin/bash
#
# Purpose: The NOAA LC curve is used on images from the 3.9 micron shortwave infrared channel (CH2) of GOES. 
#	   It provides maximum enhancement in the temperature range where fog and low clouds typically occur (36C to -9C). 
#	   Another enhanced thermal range is from -10C to -29C, the region of precipitation generation in mid- latitude weather systems. 
# 	   Since CH2 is sensitive to hot spots, a steep, reverse ramp is found at the warm end (68C to 50C) to show any observable fires as white. 
# 	   There is no enhancement at the very cold end (-30 to -67C), due to the instrument noise normally present at these temperatures. 
# 	   This enhancement option is temperature normalised.
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
$WXTOIMG -o -m "${MAP_OVERLAY}" ${extra_args} -e "LC" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
