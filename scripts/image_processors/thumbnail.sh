#!/bin/bash
#
# Purpose: Produce a thumbnail image for a given input file, storing in specified output file.
#
# Input parameters:
#   1. Width in pixels
#   1. Input image file
#   2. Desired output thumbnail image
#
# Example:
#   ./thumbnail.sh 300 /path/to/input_file.png /path/to/output_thumbnail.png

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
WIDTH_PIXELS=$1
IN_IMAGE_FILE=$2
OUT_THUMBNAIL_FILE=$3

$CONVERT -interlace Line -thumbnail $WIDTH_PIXELS "${IN_IMAGE_FILE}" "${OUT_THUMBNAIL_FILE}"
