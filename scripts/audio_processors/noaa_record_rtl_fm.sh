#!/bin/bash
#
# Purpose: Record NOAA audio via gnuradio to a wav file.
#
# Inputs:
#   1. noaa_sat_name: Satellite name ('NOAA 15', 'NOAA 18', 'NOAA 19')
#   2. capture_time: Time (in seconds) for length capture
#   3. out_wav_file: fully-qualified filename for output wav file, including '.wav' extension
#
# Example (record NOAA audio at for 15 seconds, output to /srv/audio/meteor/NOAA18.wav):
#   ./record_noaa.sh 15 /srv/audio/noaa/NOAA18.wav

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
SAT_NAME=$1
CAPTURE_TIME=$2
OUT_FILE=$3

# determine what frequency based on NOAA variant
case $SAT_NAME in
  "NOAA 15")
    freq=$NOAA15_FREQ
    ;;
  "NOAA 18")
    freq=$NOAA18_FREQ
    ;;
  "NOAA 19")
    freq=$NOAA19_FREQ
    ;;
  *)
    log "Satellite $SAT_NAME is not valid - please use one of ['NOAA 15', 'NOAA 18', 'NOAA 19']." "ERROR"
    exit 1
esac

# check that filename extension is wav (only type supported currently)
if [ ${OUT_FILE: -4} != ".wav" ]; then
  log "Output file must end in .wav extension." "ERROR"
  exit 1
fi

log "Recording at ${freq} MHz..." "INFO"
if [ ${GAIN} == 0 ]; then
timeout "${CAPTURE_TIME}" $RTL_FM -d ${SDR_DEVICE_ID} ${BIAS_TEE} -f "${freq}"M -p "${FREQ_OFFSET}" -s 60k  -E wav -E deemp -F 9 - | $SOX -t raw -e signed -c 1 -b 16 -r 60000 - "${OUT_FILE}" rate 11025
else
timeout "${CAPTURE_TIME}" $RTL_FM -d ${SDR_DEVICE_ID} ${BIAS_TEE} -f "${freq}"M -p "${FREQ_OFFSET}" -s 60k -g "${GAIN}" -E wav -E deemp -F 9 - | $SOX -t raw -e signed -c 1 -b 16 -r 60000 - "${OUT_FILE}" rate 11025
fi
