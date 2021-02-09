#!/bin/bash
#
# Purpose: Multispectral analysis. Uses a NOAA channel 2-4 image and determines which
#          regions are most likely to be cloud, land, or sea based on an analysis of the two
#          images. Produces a vivid false-coloured image as a result.
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

# produce the output image
$WXTOIMG -o -m "${MAP_OVERLAY}" -e "MSA" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
