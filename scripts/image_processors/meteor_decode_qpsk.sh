#!/bin/bash
#
# Purpose: Decode Meteor-M 2 qpsk file to .bmp image file.
#
# Input parameters:
#   1. Input QPSK .qpsk file
#   2. Output filename for .bmp file
#
# Example:
#   ./meteor_decode.sh /path/to/input.qpsk /path/to/output.bmp

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_QPSK=$1
OUTPUT_BMP=$2

# produce the output image
$MEDET_ARM "${INPUT_QPSK}" "${OUTPUT_BMP}" -cd
