#!/bin/bash
#
# Purpose: Produce a histogram for a given input file and specified output file.
#
# Input parameters:
#   1. Input any image format
#   2. Desired output any image format
#   3. Title for the produced histogram chart
#   4. Additional comment (lower left) for the histogram chart
#
# Example:
#   ./histogram.sh /path/to/inputfile.png /path/to/outputfile.jpg "my chart title" "my chart comment"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# change input params to sane names for readability
IN_FILE=$1
OUT_FILE=$2
CHART_TITLE=$3
CHART_COMMENT=$4

# produce the histogram on a pristine image. 
# ToDO: This should be updated to strip the telemetry first. And produce two histograms, one ofr each channel.
gmic "${IN_FILE}" +histogram 256 display_graph[-1] 400,300,1,0,255,0 outputp
created_file="_${IN_FILE%.*}~.jpg"
convert "${created_file}" "${OUT_FILE}"
rm "${created_file}"
rm "_${IN_FILE}"
convert "${OUT_FILE}" -undercolor grey85 -fill black -pointsize 12 -annotate +5+12  "${CHART_TITLE}" "${OUT_FILE}"
convert "${OUT_FILE}" -gravity SouthWest -undercolor grey85 -fill black -pointsize 12 -annotate +5+1 "${CHART_COMMENT}" "${OUT_FILE}"



