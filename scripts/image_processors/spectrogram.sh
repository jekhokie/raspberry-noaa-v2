#!/bin/bash
#
# Purpose: Produce a spectrogram for a given input file and specified output file.
#
# Input parameters:
#   1. Input .wav file
#   2. Desired output .png file
#   3. Title for the produced spectrogram chart
#   4. Additional comment (lower left) for the spectrogram chart
#
# Example:
#   ./spectrogram.sh /path/to/inputfile.wav /path/to/outputfile.png "my chart title" "my chart comment"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
IN_WAV_FILE=$1
OUT_PNG_FILE=$2
CHART_TITLE=$3
CHART_COMMENT=$4

# produce the spectrogram
$SOX "${IN_WAV_FILE}" -n spectrogram -t "${CHART_TITLE}" -x 1024 -y 257 -c "${CHART_COMMENT}" -o "${OUT_PNG_FILE}"
