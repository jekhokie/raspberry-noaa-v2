#!/bin/bash
#
# Purpose: Record Meteor-M audio via gnuradio to a bitstream file.
#
# Inputs:
#   1. capture_time: time (in seconds) for length capture
#   2. out_s_file: fully-qualified filename for output bitstream file, including '.s' extension
#
# Example (record meteor audio for 15 seconds, output to /srv/audio/meteor/METEORM2.s):
#   ./meteor_record_gnuradio.sh 15 /srv/audio/meteor/METEORM2.s

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
CAPTURE_TIME=$1
OUT_FILE=$2

# check that filename extension is bitstream (only type supported currently)
if [ ${OUT_FILE: -2} != ".s" ]; then
  log "Output file must end in .s extension." "ERROR"
  exit 1
fi

timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/rtlsdr_m2_lrpt_rx.py" "${OUT_FILE}" "${GAIN}" "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
