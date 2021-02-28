#!/bin/bash
#
# Purpose: Record Meteor-M audio via rtl_fm to a wav file.
#
# Inputs:
#   1. capture_time: time (in seconds) for length capture
#   2. out_wav_file: fully-qualified filename for output wav file, including '.wav' extension
#
# Example (record meteor audio for 15 seconds, output to /srv/audio/meteor/METEORM2.wav):
#   ./meteor_record_rtl_fm.sh 15 /srv/audio/meteor/METEORM2.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
CAPTURE_TIME=$1
OUT_FILE=$2

# check that filename extension is wav (only type supported currently)
if [ ${OUT_FILE: -4} != ".wav" ]; then
  log "Output file must end in .wav extension." "ERROR"
  exit 1
fi

log "Recording at ${METEOR_FREQ} MHz..." "INFO"
timeout "${CAPTURE_TIME}" $RTL_FM -d ${SDR_DEVICE_ID} ${BIAS_TEE} -M raw -f "${METEOR_FREQ}"M -s 288k -g "${GAIN}" | $SOX -t raw -r 288k -c 2 -b 16 -e s - -t wav "${OUT_FILE}" rate 96k >> $NOAA_LOG 2>&1
