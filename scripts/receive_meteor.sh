#!/bin/bash
#
# Purpose: Receive and process Meteor-M 2 captures.
#
# Input parameters:
#   1. Name of satellite "METEOR-M 2"
#   2. Filename of image outputs
#   3. Epoch start time for capture
#   4. Duration of capture (seconds)
#   5. Max angle elevation for satellite
#
# Example:
#   ./receive_meteor.sh "METEOR-M 2" METEOR-M220210205-192623 1612571183 922 39

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
capture_start=$START_DATE

# input params
SAT_NAME=$1
FILENAME_BASE=$2
EPOCH_START=$3
CAPTURE_TIME=$4
SAT_MAX_ELEVATION=$5

# base directory plus filename_base for re-use
RAMFS_AUDIO_BASE="${RAMFS_AUDIO}/${FILENAME_BASE}"
AUDIO_FILE_BASE="${METEOR_AUDIO_OUTPUT}/${FILENAME_BASE}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME_BASE}"
IMAGE_THUMB_BASE="${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}"

in_mem=true
SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
  log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
  RAMFS_AUDIO_BASE="${METEOR_AUDIO_OUTPUT}/${FILENAME_BASE}"
  in_mem=false
fi

FLIP=""
if [ "$FLIP_METEOR_IMG" == "true" ]; then
  log "I'll flip this image pass because FLIP_METEOR_IMG is set to true" "INFO"
  FLIP="-rotate 180"
fi

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
SUN_ELEV=$(python3 "$SCRIPTS_DIR"/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
  pkill -9 -f rtl_fm
fi

log "Starting rtl_fm record" "INFO"
${AUDIO_PROC_DIR}/meteor_record.sh $CAPTURE_TIME "${RAMFS_AUDIO_BASE}.wav" >> $NOAA_LOG 2>&1

log "Demodulation in progress (QPSK)" "INFO"
qpsk_file="${NOAA_HOME}/tmp/meteor/${FILENAME_BASE}.qpsk"
${AUDIO_PROC_DIR}/meteor_demodulate.sh "${qpsk_file}" "${RAMFS_AUDIO_BASE}.wav" >> $NOAA_LOG 2>&1

spectrogram=0
if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  log "Producing spectrogram" "INFO"
  spectrogram=1
  spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
  ${IMAGE_PROC_DIR}/spectrogram.sh "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" spectro_text >> $NOAA_LOG 2>&1
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png" >> $NOAA_LOG 2>&1
fi

if [ "$DELETE_AUDIO" = true ]; then
  log "Deleting audio files" "INFO"
  rm "${RAMFS_AUDIO_BASE}.wav"
else
  if [ "$in_mem" == "true" ]; then
    log "Moving audio files out to the SD card" "INFO"
    mv "${RAMFS_AUDIO_BASE}.wav" "${AUDIO_FILE_BASE}.wav"
    rm "${RAMFS_AUDIO_BASE}.wav"
  fi
fi

log "Decoding in progress (QPSK to BMP)" "INFO"
${IMAGE_PROC_DIR}/meteor_decode.sh "${qpsk_file}" "${AUDIO_FILE_BASE}" >> $NOAA_LOG 2>&1

rm "${qpsk_file}"

if [ -f "${AUDIO_FILE_BASE}.dec" ]; then
  if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
    log "I got a successful ${FILENAME_BASE}.dec file. Decoding APID 68" "INFO"
    ${IMAGE_PROC_DIR}/meteor_apid68_decode.sh "${AUDIO_FILE_BASE}.dec" "${IMAGE_FILE_BASE}-122" >> $NOAA_LOG 2>&1
    $CONVERT $FLIP -negate "${IMAGE_FILE_BASE}-122.bmp" "${IMAGE_FILE_BASE}-122.bmp" >> $NOAA_LOG 2>&1
  else
    log "I got a successful ${FILENAME_BASE}.dec file. Creating false color image" "INFO"
    ${IMAGE_PROC_DIR}/meteor_false_color_decode.sh "${AUDIO_FILE_BASE}.dec" "${IMAGE_FILE_BASE}-122" >> $NOAA_LOG 2>&1
  fi

  log "Rectifying image to adjust aspect ratio" "INFO"
  python3 "${NOAA_HOME}/scripts/image_processors/meteor_rectify.py" "${IMAGE_FILE_BASE}-122.bmp" >> $NOAA_LOG 2>&1

  annotation="${SAT_NAME} ${capture_start} Elev: $SAT_MAX_ELEVATION°"
  ${IMAGE_PROC_DIR}/meteor_normalize_annotate.sh "${IMAGE_FILE_BASE}-122-rectified.jpg" "${annotation}" >> $NOAA_LOG 2>&1
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-122-rectified.jpg" "${IMAGE_THUMB_BASE}-122-rectified.jpg" >> $NOAA_LOG 2>&1
  rm "${IMAGE_FILE_BASE}-122.bmp"
  rm "${AUDIO_FILE_BASE}.bmp"
  rm "${AUDIO_FILE_BASE}.dec"

  # insert or replace in case there was already an insert due to the spectrogram creation
  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START,\"$FILENAME_BASE\", 1, 0, $spectrogram);"
  pass_id=$(sqlite3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
  $SQLITE3 $DB_FILE "UPDATE predict_passes SET is_active = 0 WHERE (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"
else
  log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
