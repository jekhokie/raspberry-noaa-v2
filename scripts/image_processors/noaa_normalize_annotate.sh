#!/bin/bash
#
# Purpose: Reduce image size/quality and add annotation text inline with image
#          (overwrites input image) for a NOAA capture.
#
# Input parameters:
#   1. Input .jpg file
#   2. Annotation text
#   3. Image quality percent (whole number)
#
# Example:
#   ./noaa_normalize_annotate.sh /path/to/inputfile.jpg "annotation text"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_JPG=$1
ANNOTATION_TEXT=$2
QUALITY=$3

$CONVERT -quality $QUALITY -format jpg "${INPUT_JPG}" -gravity $IMAGE_ANNOTATION_LOCATION -undercolor black -fill yellow -pointsize 18 -annotate +10+10 "${ANNOTATION_TEXT}" "${INPUT_JPG}"
