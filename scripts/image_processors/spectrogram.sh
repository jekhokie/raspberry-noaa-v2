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

CHART_TEXT="${CHART_TITLE} ${CHART_COMMENT}"

# produce the spectrogram on a single channel (the first one)
$FFMPEG -y -i ${IN_WAV_FILE} -lavfi showspectrumpic=s=800x400:mode=separate ${OUT_PNG_FILE}.mez.png

# add the title text
$FFMPEG -y -i ${OUT_PNG_FILE}.mez.png -vf "drawtext=fontfile=/path/to/font.ttf:text='${CHART_TEXT}':fontcolor=white:fontsize=18:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=10" ${OUT_PNG_FILE}

rm ${OUT_PNG_FILE}.mez.png

