#!/bin/bash
#
# Purpose: Creates raw images (2) of each channel (A/B) of a NOAA capture.
#
# Input parameters:
#   1. Input .wav file
#   2. Output -a.jpg file
#   3. Output -b.jpg file
#
# Example:
#   ./noaa_histogram_data.sh  /path/to/input.wav /path/to/output-a.png /path/to/output-b.png

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_WAV=$1
OUTPUT_IMAGE_A=$2
OUTPUT_IMAGE_B=$3

# produce the raw output image
$WXTOIMG -o -a -c -r -16 "${INPUT_WAV}" "${OUTPUT_IMAGE_A}"
$WXTOIMG -o -b -c -r -16 "${INPUT_WAV}" "${OUTPUT_IMAGE_B}"
