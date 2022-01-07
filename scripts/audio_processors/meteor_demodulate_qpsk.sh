#!/bin/bash
#
# Purpose: Demodulate Meteor-M 2 audio file in QPSK format.
#
# Input parameters: (note the output.wav is the input to generate the output.qpsk)
#   1. Input .wav file
#   2. Output QPSK file
#
# Example:
#   ./demodulate_meteor_qpsk.sh /path/to/input.qpsk /path/to/output.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_WAV=$1
OUTPUT_QPSK=$2


# produce the output image - note QPSK output lists before wav
$METEORDEMOD -B -o "${OUTPUT_QPSK}" "${INPUT_WAV}" >> $NOAA_LOG 2>&1
