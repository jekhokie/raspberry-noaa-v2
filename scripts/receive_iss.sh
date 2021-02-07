#!/bin/bash

# run as a normal user
if [ $EUID -eq 0 ]; then
  echo "This script shouldn't be run as root."
  exit 1
fi

# import common lib
. "$HOME/.noaa-v2.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
ISS_NAME=$1
FREQ=$2
FILENAME=$3
EPOCH_START=$5
CAPTURE_TIME=$6
ISS_MAX_ELEVATION=$7

if pgrep "rtl_fm" > /dev/null; then
  log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
  pkill -9 -f rtl_fm
fi

log "Starting rtl_fm record" "INFO"
timeout "${CAPTURE_TIME}" /usr/local/bin/rtl_fm ${BIAS_TEE} -M fm -f "${FREQ}"M -s 48k -g $GAIN -E dc -E wav -E deemp -F 9 - | sox -t raw -r 48k -c 1 -b 16 -e s - -t wav "${NOAA_AUDIO_OUTPUT}/${FILENAME}.wav" rate 11025

spectrogram=0
if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  log "Producing spectrogram" "INFO"
  spectrogram=1
  spectrogram_text="${START_DATE} @ ${ISS_MAX_ELEVATION}°"
  sox "${NOAA_AUDIO_OUTPUT}/${FILENAME}.wav" -n spectrogram -t "${SAT_NAME}" -x 1024 -y 257 -c "${spectrogram_text}" -o "${IMAGE_OUTPUT}/${FILENAME}-spectrogram.png"
  /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME}-spectrogram.png" "${IMAGE_OUTPUT}/thumb/${FILENAME}-spectrogram.png"
fi

if [ -f "$NOAA_HOME/scripts/demod.py" ]; then
  log "Decoding ISS pass" "INFO"
  python3 "$NOAA_HOME/scripts/demod.py" "${NOAA_AUDIO_OUTPUT}/${FILENAME}.wav" "${IMAGE_OUTPUT}/"
  decoded_pictures="$(find ${IMAGE_OUTPUT}/ -iname "${FILENAME}*png")"
  img_count=0
  for image in $decoded_pictures; do
    log "Decoded image: $image" "INFO"
    ((img_count++))
  done

  if [ "$img_count" -gt 0 ]; then
    /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME}-0.png" "${IMAGE_OUTPUT}/thumb/${FILENAME}-0.png"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, img_count, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME\", 1, 2, $img_count, $spectrogram);"
    pass_id=$(sqlite3 "$DB_FILE" "select id from decoded_passes order by id desc limit 1;")
    sqlite3 "$DB_FILE" "UPDATE predict_passes SET is_active = 0 WHERE (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

    if [ -n "$CONSUMER_KEY" ]; then
      log "Posting to Twitter" "INFO"
      if [ "$img_count" -eq 1 ]; then
        python3 $NOAA_HOME/scripts/post.py "$ISS_NAME ${START_DATE} Resolución completa: https://weather.reyni.co/detail.php?id=$pass_id" "$ISS_MAX_ELEVATION" "${IMAGE_OUTPUT}/${FILENAME}-0.png"
      elif [ "$img_count" -eq 2 ]; then
        /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME}-1.png" "${IMAGE_OUTPUT}/thumb/${FILENAME}-1.png"
        python3 $NOAA_HOME/scripts/post.py "$ISS_NAME ${START_DATE} Mas imagenes: https://weather.reyni.co/detail.php?id=$pass_id" "$ISS_MAX_ELEVATION" "${IMAGE_OUTPUT}/${FILENAME}-0.png" "${IMAGE_OUTPUT}/${FILENAME}-1.png"
      fi
    fi
  fi
fi
