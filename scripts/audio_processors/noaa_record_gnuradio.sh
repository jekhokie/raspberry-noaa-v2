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

if [ "$RECEIVER_TYPE" == "rtlsdr" ]; then
  log "Recording ${NOAA_HOME} via RTL-SDR at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/rtlsdr_noaa_apt_rx.py" "${OUT_FILE}" "${GAIN}" "${freq}"M "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
  ffmpeg -hide_banner -loglevel error -i "$3" -c:a copy "${3%.*}_tmp.wav" && ffmpeg -i "${3%.*}_tmp.wav" -c:a copy -y "$3" && rm "${3%.*}_tmp.wav"
fi

if [ "$RECEIVER_TYPE" == "airspy_r2" ]; then
  log "Recording ${NOAA_HOME} via Airspy R2 at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/airspy_r2_noaa_apt_rx.py" "${OUT_FILE}" "${GAIN}" "${freq}"M "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
  ffmpeg -hide_banner -loglevel error -i "$3" -c:a copy "${3%.*}_tmp.wav" && ffmpeg -i "${3%.*}_tmp.wav" -c:a copy -y "$3" && rm "${3%.*}_tmp.wav"
fi

if [ "$RECEIVER_TYPE" == "airspy_mini" ]; then
  log "Recording ${NOAA_HOME} via Airspy Mini at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/airspy_mini_noaa_apt_rx.py" "${OUT_FILE}" "${GAIN}" "${freq}"M "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
  ffmpeg -hide_banner -loglevel error -i "$3" -c:a copy "${3%.*}_tmp.wav" && ffmpeg -i "${3%.*}_tmp.wav" -c:a copy -y "$3" && rm "${3%.*}_tmp.wav"
fi

if [ "$RECEIVER_TYPE" == "hackrf" ]; then
  log "Recording ${NOAA_HOME} via Airspy R2 at ${freq} MHz...to " "INFO"
  timeout "${CAPTURE_TIME}" "$NOAA_HOME/scripts/audio_processors/hackrf_noaa_apt_rx.py" "${OUT_FILE}" "${GAIN}" "${freq}"M "${FREQ_OFFSET}" "${SDR_DEVICE_ID}" "${BIAS_TEE}" >> $NOAA_LOG 2>&1
  ffmpeg -hide_banner -loglevel error -i "$3" -c:a copy "${3%.*}_tmp.wav" && ffmpeg -i "${3%.*}_tmp.wav" -c:a copy -y "$3" && rm "${3%.*}_tmp.wav"
fi
