#!/bin/bash

# run as a normal user
if [ $EUID -eq 0 ]; then
  echo "ERROR: This script shouldn't be run as root"
  exit 1
fi

# import common lib
. "$HOME/.noaa-v2.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/scripts/common.sh"

in_mem=true
SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
  log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
  RAMFS_AUDIO="${METEOR_AUDIO_OUTPUT}"
  in_mem=false
fi

if [ "$FLIP_METEOR_IMG" == "true" ]; then
  log "Flipping this image pass because FLIP_METEOR_IMG is set to true" "INFO"
  FLIP="-rotate 180"
else
  FLIP=""
fi

# organize inputs
SAT_NAME=$1
FREQUENCY=$2
FILENAME=$3
TLE_FILE=$4
EPOCH_START=$5
CAPTURE_LENGTH=$6
SAT_MAX_ELEVATION=$7

# keeping things DRY
AUDIO_FILE_BASE="${RAMFS_AUDIO}/${FILENAME}"
IMAGE_FILE_TMP="${NOAA_HOME}/tmp/meteor/${FILENAME}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME}"

## pass start timestamp and sun elevation
PASS_START=$(expr "${EPOCH_START}" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/scripts/sun.py "${PASS_START}")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
  pkill -9 -f rtl_fm
fi

log "Starting rtl_fm record" "INFO"
timeout "${CAPTURE_LENGTH}" python ${NOAA_HOME}/scripts/rtlsdr_m2_lrpt_rx.py ${AUDIO_FILE_BASE} ${GAIN} ${FREQ_OFFSET}

sleep 5
log "Decoding in progress (QPSK to BMP)" "INFO"
medet_arm ${AUDIO_FILE_BASE}.s ${IMAGE_FILE_TMP} -r 68 -g 65 -b 64 -na -s

if [[ "${DELETE_AUDIO}" == "true" ]]; then
  log "Deleting audio files" "INFO"
  rm -f "${AUDIO_FILE_BASE}.s"
else
  if [[ "${in_mem}" == "true" ]]; then
    log "Moving audio files out to the SD card" "INFO"
    mv "${AUDIO_FILE_BASE}.s" "${METEOR_AUDIO_OUTPUT}/"
  fi
fi

if [ -f "${IMAGE_FILE_TMP}_0.bmp" ]; then
  log "Post-processing in progress" "INFO"

  convert ${IMAGE_FILE_TMP}_1.bmp ${IMAGE_FILE_TMP}_1.bmp ${IMAGE_FILE_TMP}_0.bmp -combine -set colorspace sRGB ${IMAGE_FILE_TMP}.bmp
  convert ${IMAGE_FILE_TMP}_2.bmp ${IMAGE_FILE_TMP}_2.bmp ${IMAGE_FILE_TMP}_2.bmp -combine -set colorspace sRGB -negate ${IMAGE_FILE_TMP}_ir.bmp

  python3 ${NOAA_HOME}/scripts/rectify.py ${IMAGE_FILE_TMP}.bmp
  python3 ${NOAA_HOME}/scripts/rectify.py ${IMAGE_FILE_TMP}_ir.bmp

  convert ${IMAGE_FILE_TMP}-rectified.jpg ${FLIP} -normalize -quality 90 ${IMAGE_FILE_TMP}.jpg
  convert ${IMAGE_FILE_TMP}_ir-rectified.jpg ${FLIP} -normalize -quality 90 ${IMAGE_FILE_TMP}_ir.jpg

  log "Compressing and adding to images folder" "INFO"

  ANNOTATION="${SAT_NAME} ${START_DATE} Elev: ${SAT_MAX_ELEVATION}°"
  convert "${IMAGE_FILE_TMP}.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${ANNOTATION}" "${IMAGE_OUTPUT}/${FILENAME}-122-rectified.jpg"
  convert -thumbnail 300 "${IMAGE_FILE_TMP}.jpg" "${IMAGE_OUTPUT}/thumb/${FILENAME}-122-rectified.jpg"
  convert "${IMAGE_FILE_TMP}_ir.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${ANNOTATION}" "${IMAGE_OUTPUT}/${FILENAME}-122-rectified-ir.jpg"
  convert -thumbnail 300 "${IMAGE_FILE_TMP}_ir.jpg" "${IMAGE_OUTPUT}/thumb/${FILENAME}-122-rectified-ir.jpg"

  log "Updating DB" "INFO"

  sqlite3 $DB_FILE "insert into decoded_passes (pass_start, file_path, daylight_pass, sat_type) values ($EPOCH_START, \"${FILENAME}\", 1,0);"
  pass_id=$(sqlite3 $DB_FILE "select id from decoded_passes order by id desc limit 1;")
  sqlite3 $DB_FILE "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

  log "Cleaning up" "INFO"
  rm -f ${IMAGE_FILE_TMP}*.bmp
  rm -f ${IMAGE_FILE_TMP}*.jpg

  log "METEOR M2 processing complete and successful" "INFO"
else
  log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
