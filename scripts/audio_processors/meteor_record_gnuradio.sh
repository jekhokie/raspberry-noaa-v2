
#!/bin/bash
#
# Purpose: Record Meteor-M audio via rtl_fm to a wav file.
#
# Inputs:
#   1. capture_time: Time (in seconds) for length capture
#   2. out_wav_file: fully-qualified filename for output wav file, including '.wav' extension
#
# Example (record meteor audio at for 15 seconds, output to /srv/audio/meteor/METEORM2.wav):
#   ./record_meteor.sh 15 /srv/audio/meteor/METEORM2.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
CAPTURE_TIME=$1
OUT_FILE=$2
GAIN=$3
PPM=$4

# check that filename extension is wav (only type supported currently)
#if [ ${OUT_FILE: -4} != ".wav" ]; then
#  log "Output file must end in .wav extension." "ERROR"
#  exit 1
#fi

log "Recording at ${METEOR_FREQ} MHz..." "INFO"
#timeout "${CAPTURE_TIME}" $RTL_FM ${BIAS_TEE} -M raw -f "${METEOR_FREQ}"M -s 288k -g $GAIN | $SOX -t raw -r 288k -c 2 -b 16 -e s - -t wav "${OUT_FILE}" rate 96k

timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/rtlsdr_m2_lrpt_rx.py" "${SAT_NAME}" "${METEOR_FREQ}"M "${OUT_FILE}".s "${GAIN}" "${PPM}"



