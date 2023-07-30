#!/bin/bash
#
# Purpose: Record Meteor-M audio via gnuradio to a bitstream file.
#
# Inputs:
#   1. capture_time: time (in seconds) for length capture
#   2. out_wav_file: fully-qualified filename for output baseband file, including '.wav' extension
#
# Example (record meteor audio for 15 seconds, output to /srv/audio/meteor/METEORM2.wav):
#   ./meteor_record_gnuradio.sh 15 /srv/audio/meteor/METEORM2.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
CAPTURE_TIME=$1
OUT_FILE=$2

# check that filename extension is bitstream (only type supported currently)
if [ ${OUT_FILE: -4} != ".wav" ]; then
  log "Output file must end in .wav extension." "ERROR"
  exit 1
fi

if [ "$RECEIVER_TYPE" == "rtlsdr" ]; then
  log "Recording ${NOAA_HOME} via RTL-SDR at ${METEOR_FREQ} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/rtlsdr_m2_lrpt_rx.py" "${OUT_FILE}" "${GAIN}" "${METEOR_FREQ}" "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
fi

if [ "$RECEIVER_TYPE" == "airspy_r2" ]; then
  log "Recording ${NOAA_HOME} via Airspy R2 at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/airspy_r2_m2_lrpt_rx.py" "${OUT_FILE}" "${GAIN}" "${METEOR_FREQ}" "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
fi

if [ "$RECEIVER_TYPE" == "airspy_mini" ]; then
  log "Recording ${NOAA_HOME} via Airspy R2 at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/airspy_mini_m2_lrpt_rx.py" "${OUT_FILE}" "${GAIN}" "${METEOR_FREQ}" "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
fi

if [ "$RECEIVER_TYPE" == "hackrf" ]; then
  log "Recording ${NOAA_HOME} via Airspy R2 at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/hackrf_m2_lrpt_rx.py" "${OUT_FILE}" "${GAIN}" "${METEOR_FREQ}" "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
fi
