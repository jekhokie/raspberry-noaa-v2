#!/bin/bash
#
# Purpose: Reduce image size/quality and add annotation text inline with image
#          (overwrites input image) for a METEOR capture.
#
# Input parameters:
#   1. Input .jpg file
#   2. Annotation text
#
# Example:
#   ./meteor_normalize_annotate.sh /path/to/inputfile.jpg "annotation text"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_JPG=$1
ANNOTATION_TEXT=$2
QUALITY=$3

$CONVERT "${INPUT_JPG}" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${ANNOTATION_TEXT}" "${INPUT_JPG}"
