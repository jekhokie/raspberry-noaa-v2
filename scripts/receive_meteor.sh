#!/bin/bash

### Run as a normal user
if [ $EUID -eq 0 ]; then
  echo "This script shouldn't be run as root."
  exit 1
fi

## import common lib
. "$HOME/.noaa-v2.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
SAT_NAME=$1
FREQ=$2
FILENAME_BASE=$3
EPOCH_START=$5
CAPTURE_TIME=$6
SAT_MAX_ELEVATION=$7

# base directory plus filename_base for re-use
FILENAME="${METEOR_AUDIO_OUTPUT}/${FILENAME_BASE}"

in_mem=true
SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
  log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
  RAMFS_AUDIO="${METEOR_AUDIO_OUTPUT}"
  in_mem=false
fi

FLIP=""
if [ "$FLIP_METEOR_IMG" == "true" ]; then
  log "I'll flip this image pass because FLIP_METEOR_IMG is set to true" "INFO"
  FLIP="-rotate 180"
fi

## pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/scripts/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
  pkill -9 -f rtl_fm
fi

log "Starting rtl_fm record" "INFO"
timeout "${CAPTURE_TIME}" /usr/local/bin/rtl_fm ${BIAS_TEE} -M raw -f "${FREQ}"M -s 288k -g $GAIN | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav "${RAMFS_AUDIO}/${FILENAME_BASE}.wav" rate 96k

log "Demodulation in progress (QPSK)" "INFO"
meteor_demod -B -o "${NOAA_HOME}/tmp/meteor/${FILENAME_BASE}.qpsk" "${RAMFS_AUDIO}/${FILENAME_BASE}.wav"

if [[ "$PRODUCE_SPECTROGRAM}" == "true" ]]; then
  log "Producing spectrogram" "INFO"
  spectrogram_text="${START_DATE} @ ${SAT_MAX_ELEVATION}°"
  sox "${RAMFS_AUDIO}/${FILENAME_BASE}.wav" -n spectrogram -t "${SAT_NAME}" -x 1024 -y 257 -c "${spectrogram_text}" -o "${IMAGE_OUTPUT}/${FILENAME_BASE}-spectrogram.png"
  /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME_BASE}-spectrogram.png" "${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}-spectrogram.png"
  sqlite3 $DB_FILE "INSERT INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME_BASE\", 1, 0, 1);"
fi

if [ "$DELETE_AUDIO" = true ]; then
  log "Deleting audio files" "INFO"
  rm "${RAMFS_AUDIO}/${FILENAME_BASE}.wav"
else
  if [ "$in_mem" == "true" ]; then
    log "Moving audio files out to the SD card" "INFO"
    mv "${RAMFS_AUDIO}/${FILENAME_BASE}.wav" "${FILENAME}.wav"
    rm "${RAMFS_AUDIO}/${FILENAME_BASE}.wav"
  fi
fi

log "Decoding in progress (QPSK to BMP)" "INFO"
medet_arm "${NOAA_HOME}/tmp/meteor/${FILENAME_BASE}.qpsk" "${FILENAME}" -cd

rm "${NOAA_HOME}/tmp/meteor/${FILENAME_BASE}.qpsk"

if [ -f "${FILENAME}.dec" ]; then
  if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
    log "I got a successful ${FILENAME_BASE}.dec file. Decoding APID 68" "INFO"
    medet_arm "${FILENAME}.dec" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122" -r 68 -g 68 -b 68 -d
    /usr/bin/convert $FLIP -negate "${IMAGE_OUTPUT}/${FILENAME_BASE}-122.bmp" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122.bmp"
  else
    log "I got a successful ${FILENAME_BASE}.dec file. Creating false color image" "INFO"
    medet_arm "${FILENAME}.dec" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122" -r 65 -g 65 -b 64 -d
  fi

  log "Rectifying image to adjust aspect ratio" "INFO"
  python3 "${NOAA_HOME}/scripts/rectify.py" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122.bmp"
  convert "${IMAGE_OUTPUT}/${FILENAME_BASE}-122-rectified.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${SAT_NAME} ${START_DATE} Elev: $SAT_MAX_ELEVATION°" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122-rectified.jpg"
  /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME_BASE}-122-rectified.jpg" "${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}-122-rectified.jpg"
  rm "${IMAGE_OUTPUT}/${FILENAME_BASE}-122.bmp"
  rm "${FILENAME}.bmp"
  rm "${FILENAME}.dec"

  # insert or replace in case there was already an insert due to the spectrogram creation
  sqlite3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type) VALUES ($EPOCH_START,\"$FILENAME_BASE\", 1, 0);"
  pass_id=$(sqlite3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
  sqlite3 $DB_FILE "UPDATE predict_passes SET is_active = 0 WHERE (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"
  if [ -n "$CONSUMER_KEY" ]; then
    log "Posting to Twitter" "INFO"
    python3 $NOAA_HOME/scripts/post.py "$SAT_NAME ${START_DATE} Resolución completa: https://weather.reyni.co/detail.php?id=$pass_id" "$SAT_MAX_ELEVATION" "${IMAGE_OUTPUT}/${FILENAME_BASE}-122-rectified.jpg"
  fi
else
  log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
