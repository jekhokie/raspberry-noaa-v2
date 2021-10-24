#!/bin/bash
#
# Purpose: Decode Meteor-M 2 bitstream audio file to .bmp image file.
#
# Input parameters:
#   1. Input bitstream .s file
#   2. Output filename for .bmp file
#
# Example:
#   ./meteor_decode.sh /path/to/input.s /path/to/output.bmp

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_BITSTREAM=$1
OUTPUT_BMP=$2

# TODO: Figure out how to programmatical determine winter vs. summer
# produce the output image
#  winter
$MEDET_ARM "${INPUT_BITSTREAM}" "${OUTPUT_BMP}" -cd -r 68 -g 65 -b 64 -na -s
#  summer
#$MEDET_ARM "${INPUT_BITSTREAM}" "${OUTPUT_BMP}" -r 66 -g 65 -b 64 -na -s
