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
####${AUDIO_PROC_DIR}/meteor_record.sh $CAPTURE_TIME "${RAMFS_AUDIO_BASE}" #note i have removed .wav here

#sleep to allow files to close.
echo "sleeping"
sleep 2


log "Demodulation in progress (.s)" "INFO"
s_file="${RAMFS_AUDIO_BASE}"
####${IMAGE_PROC_DIR}/meteor_decode.sh "${s_file}" "${RAMFS_AUDIO_BASE}"


spectrogram=0
#if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
#  log "Producing spectrogram" "INFO"
#  spectrogram=1
#  spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
#  ${IMAGE_PROC_DIR}/spectrogram.sh "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" spectro_text
#  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png"
#fi


#log "Decoding in progress (QPSK to BMP)" "INFO"
#${IMAGE_PROC_DIR}/meteor_decode.sh "${qpsk_file}" "${AUDIO_FILE_BASE}"

#rm "${qpsk_file}"

if [ -f "${RAMFS_AUDIO_BASE}_0.bmp" ]; then

  #if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
  #  log "I got a successful ${FILENAME_BASE} file. Decoding APID 68" "INFO"
  #  ${IMAGE_PROC_DIR}/meteor_apid68_decode.sh "${AUDIO_FILE_BASE}.bmp" "${IMAGE_FILE_BASE}-122"
  #  $CONVERT $FLIP -negate "${IMAGE_FILE_BASE}-122.bmp" "${IMAGE_FILE_BASE}-122.bmp"
  #else
  #  log "I got a successful ${FILENAME_BASE}.dec file. Creating false color image" "INFO"
  #  ${IMAGE_PROC_DIR}/meteor_false_color_decode.sh "${AUDIO_FILE_BASE}.dec" "${IMAGE_FILE_BASE}-122"
  #fi

  log "Post Processing in  progress" "INFO"


  # Blend and Convert
  log "Blend and combine channels in progress" "INFO"
  convert ${RAMFS_AUDIO_BASE}_1.bmp ${RAMFS_AUDIO_BASE}_1.bmp ${RAMFS_AUDIO_BASE}_0.bmp -combine -set colorspace sRGB ${RAMFS_AUDIO_BASE}.bmp
  convert ${RAMFS_AUDIO_BASE}_2.bmp ${RAMFS_AUDIO_BASE}_2.bmp ${RAMFS_AUDIO_BASE}_2.bmp -combine -set colorspace sRGB -negate ${RAMFS_AUDIO_BASE}_ir.bmp
  convert ${RAMFS_AUDIO_BASE}_0.bmp ${RAMFS_AUDIO_BASE}_1.bmp ${RAMFS_AUDIO_BASE}_2.bmp -combine -set colorspace sRGB ${RAMFS_AUDIO_BASE}_col.bmp

  log "Rectifying image to adjust aspect ratio" "INFO"
  python3 "${NOAA_HOME}/scripts/image_processors/meteor_rectify.py"  ${RAMFS_AUDIO_BASE}.bmp
  python3 "${NOAA_HOME}/scripts/image_processors/meteor_rectify.py"  ${RAMFS_AUDIO_BASE}_ir.bmp
  python3 "${NOAA_HOME}/scripts/image_processors/meteor_rectify.py"  ${RAMFS_AUDIO_BASE}_col.bmp

  log "Compressing and rotating where required." "INFO"
  if [ $dte -lt 13 ]; then
          convert ${RAMFS_AUDIO_BASE}-rectified.jpg -normalize -quality 90 ${RAMFS_AUDIO_BASE}.jpg
          convert ${RAMFS_AUDIO_BASE}_ir-rectified.jpg -normalize -quality 90 ${RAMFS_AUDIO_BASE}_ir.jpg
          convert ${RAMFS_AUDIO_BASE}_col-rectified.jpg -normalize -quality 90 ${RAMFS_AUDIO_BASE}_col.jpg
  else
          convert ${RAMFS_AUDIO_BASE}-rectified.jpg -rotate 180 -normalize -quality 90 ${RAMFS_AUDIO_BASE}.jpg
          convert ${RAMFS_AUDIO_BASE}_ir-rectified.jpg -rotate 180 -normalize -quality 90 ${RAMFS_AUDIO_BASE}_ir.jpg
          convert ${RAMFS_AUDIO_BASE}_col-rectified.jpg -rotate 180 -normalize -quality 90 ${RAMFS_AUDIO_BASE}_col.jpg
  fi


  log "Annotating where required." "INFO"
  annotation="${SAT_NAME} ${capture_start} Elev: $SAT_MAX_ELEVATION°"

  convert "${RAMFS_AUDIO_BASE}.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${annotation}" "${IMAGE_FILE_BASE}-122-rectified.jpg"
  convert -thumbnail 300 "${RAMFS_AUDIO_BASE}.jpg" "${IMAGE_THUMB_BASE}-122-rectified.jpg"
  convert "${RAMFS_AUDIO_BASE}_ir.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${annotation}" "${IMAGE_FILE_BASE}_ir-122-rectified.jpg"
  convert -thumbnail 300 "${RAMFS_AUDIO_BASE}_ir.jpg" "${IMAGE_THUMB_BASE}_ir-122-rectified.jpg"
  convert "${RAMFS_AUDIO_BASE}_col.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${annotation}" "${IMAGE_FILE_BASE}_col-122-rectified.jpg"
  convert -thumbnail 300 "${RAMFS_AUDIO_BASE}_col.jpg" "${IMAGE_THUMB_BASE}_col-122-rectified.jpg"



#  rm "${IMAGE_FILE_BASE}-122.bmp"
#  rm "${AUDIO_FILE_BASE}.bmp"
#  rm "${AUDIO_FILE_BASE}.dec"



  # insert or replace in case there was already an insert due to the spectrogram creation
  log "Update DB" "INFO"

  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START,\"$FILENAME_BASE\", 1, 0, $spectrogram);"
  pass_id=$(sqlite3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
  $SQLITE3 $DB_FILE "UPDATE predict_passes SET is_active = 0 WHERE (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

  log "Emailing to facebook forwarder" "INFO"
  # Send to email / facebook page: needs some filtration for bad images in due course
  #if [ -f "${NOAA_OUTPUT}/images/${3}-122-rectified_ir.jpg" ]; then 
  #        mpack -s ${3}-${7}-"InfraRed" ${NOAA_OUTPUT}/images/${3}-122-rectified_ir.jpg trigger@applet.ifttt.com
  #fi
  #if [ -f "${NOAA_OUTPUT}/images/${3}-122-rectified.jpg" ]; then 
  #  mpack -s ${3}-${7} ${NOAA_OUTPUT}/images/${3}-122-rectified.jpg trigger@applet.ifttt.com
  #fi





else
  log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi


#Moving Tidy up to end

if [ "$DELETE_AUDIO" = true ]; then
  log "Deleting audio files" "INFO"
#  rm "${RAMFS_AUDIO_BASE}.wav"
#  rm "${RAMFS_AUDIO_BASE}.wav.s"

else
  if [ "$in_mem" == "true" ]; then
    log "Moving audio files out to the SD card" "INFO"
#    mv "${RAMFS_AUDIO_BASE}.wav" "${AUDIO_FILE_BASE}.wav"
#    mv "${RAMFS_AUDIO_BASE}.wav.s" "${AUDIO_FILE_BASE}.wav.s"
#    rm "${RAMFS_AUDIO_BASE}.wav"
#    rm "${RAMFS_AUDIO_BASE}.wav.s"
  fi
fi