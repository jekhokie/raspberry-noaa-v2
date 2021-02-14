#!/bin/bash
#
# Purpose: Creates a pristine image that can later be used in things such as composite images.
#
# Input parameters:
#   1. Input .wav file
#   2. Output .jpg file
#
# Example:
#   ./noaa_hvc.sh /path/to/map_overlay.png /path/to/input.wav /path/to/output.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_WAV=$1
OUTPUT_IMAGE=$2

# produce the output image
$WXTOIMG -o -e "pristine" "${INPUT_WAV}" "${OUTPUT_IMAGE}"
