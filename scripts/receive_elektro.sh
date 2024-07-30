#!/bin/bash
#
# Purpose: Receive and process ELEKTRO captures.
#
# Input parameters:
#   1. Name of satellite "ELEKTRO-L3"
#   2. Filename of image outputs
#   3. Duration of capture (seconds)
#   4. epoch start time

# input params
export SAT_NAME=$1
export FILENAME_BASE=$2
export CAPTURE_TIME=$3
export EPOCH_START=$4

#time keeping
TIMER_START=$(date '+%s')

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
capture_start="$START_DATE $(date '+%Z')"

PID_FILE=${NOAA_HOME}/tmp/${EPOCH_START}_${SAT_NAME}.pid
if [ -f $PID_FILE ]; then
  log "PID file already exists. Exiting!"
  exit 0
fi
touch ${PID_FILE}
log "Created PID file ${PID_FILE}" "INFO"

GAIN=$ELEKTRO_L3_GAIN

case "$RECEIVER_TYPE" in
     "rtlsdr")
         samplerate="1.024e6"
         receiver="rtlsdr"
         ;;
     "airspy_mini")
         samplerate="3e6"
         receiver="airspy"
         ;;
     "airspy_r2")
         samplerate="2.5e6"
         receiver="airspy"
         ;;
     "airspy_hf_plus_discovery")
         samplerate="192e3"
         receiver="airspy"
         ;;
     "hackrf")
         samplerate="4e6"
         receiver="hackrf"
         ;;
     "sdrplay")
         samplerate="2e6"
         receiver="sdrplay"
         ;;
     "mirisdr")
         samplerate="2e6"
         receiver="mirisdr"
         ;;
     *)
         log "Invalid RECEIVER_TYPE value: $RECEIVER_TYPE" "INFO"
         exit 1
         ;;
esac

if [[ "$receiver" == "rtlsdr" ]]; then
  gain_option="--gain"
else
  gain_option="--general_gain"
fi

if [[ "$USE_DEVICE_STRING" == "true" ]]; then
  sdr_id_option="--source_id"
else
  sdr_id_option=""
  SDR_DEVICE_ID=""
fi

if [ "$BIAS_TEE" == "-T" ]; then
  bias_tee_option="--bias"
else
  bias_tee_option=""
fi

RAMFS_AUDIO_BASE="${RAMFS_AUDIO}/${FILENAME_BASE}"
audio_temporary_storage_directory="$(dirname "${RAMFS_AUDIO_BASE}")"
decoded_images=${audio_temporary_storage_directory}/IMAGES/ELEKTRO*/*/*.png

log "Cleanup artifacts of previous decode"
rm -rf ${audio_temporary_storage_directory}/IMAGES
rm -rf ${audio_temporary_storage_directory}/LRIT
rm -rf ${audio_temporary_storage_directory}/elektro_lrit.cadu
rm -rf ${audio_temporary_storage_directory}/.composite_cache_do_not_delete.json

log "Starting satdump... recording to ${audio_temporary_storage_directory}/elektro-${EPOCH_START}" "INFO"
$SATDUMP live elektro_lrit "$audio_temporary_storage_directory" --source $receiver --samplerate $samplerate --frequency ${ELEKTRO_L3_FREQ}e6  $sdr_id_option $SDR_DEVICE_ID $gain_option $GAIN $bias_tee_option --finish_processing --timeout $CAPTURE_TIME >> $NOAA_LOG 2>&1

push_file_list=""

got_an_image=false
if compgen -G ${decoded_images} > /dev/null; then 
  got_an_image=true
  for file in ${decoded_images}; do
     image_filename=$(basename "$file")
     new_image=${FILENAME_BASE}-${image_filename}
     mv "$file" "${IMAGE_OUTPUT}/${new_image}"
     ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_OUTPUT}/${new_image}" "${IMAGE_OUTPUT}/thumb/${new_image}" >> $NOAA_LOG 2>&1
     push_file_list="$push_file_list ${IMAGE_OUTPUT}/${new_image}"
  done
fi

if [[ $got_an_image == "true" ]]; then
  log "Valid ELEKTRO-L3 image(s) received!" "INFO"
  # pass start timestamp and sun elevation
  PASS_START=$(expr "$EPOCH_START" + 90)
  export SUN_ELEV=$(python3 "$SCRIPTS_DIR"/tools/sun.py "$PASS_START")
  export SUN_MIN_ELEV=$ELEKTRO_L3_SUN_MIN_ELEV

  # determine if pass is in daylight
  daylight=0
  if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then daylight=1; fi

  # insert or replace in case there was already an insert due to the spectrogram creation
  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram, has_polar_az_el, has_polar_direction, gain) \
                                    VALUES ($EPOCH_START, \"$FILENAME_BASE\", $daylight, 2, 0, 0, 0, $GAIN);" >> $NOAA_LOG 2>&1

  pass_id=$($SQLITE3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
  $SQLITE3 $DB_FILE "UPDATE predict_passes \
                    SET is_active = 0 \
                    WHERE (predict_passes.pass_start) \
                    IN ( \
                      SELECT predict_passes.pass_start \
                      FROM predict_passes \
                      INNER JOIN decoded_passes \
                      ON predict_passes.pass_start = decoded_passes.pass_start \
                      WHERE decoded_passes.id = $pass_id \
                    );" >> $NOAA_LOG 2>&1
                    

  # determine if auto-gain is set - handles "0" and "0.0" floats
  gain=$GAIN
  if [ $(echo "$GAIN==0"|bc) -eq 1 ]; then
    gain='Automatic'
  fi

  # create push annotation string (annotation in the email subject, discord text, etc.)
  # note this is NOT the annotation on the image, which is driven by the config/annotation/annotation.html.j2 file
  push_annotation=""
  if [ "${GROUND_STATION_LOCATION}" != "" ]; then
    push_annotation="Ground Station: ${GROUND_STATION_LOCATION}"
  fi
  push_annotation="${push_annotation} ${SAT_NAME} ${capture_start} "
  push_annotation="${push_annotation} Gain: ${gain}"
  
  # handle Pushover pushing if enabled
  if [ "${ENABLE_PUSHOVER_PUSH}" == "true" ]; then
    pushover_push_annotation=""
    #if [ "${GROUND_STATION_LOCATION}" != "" ]; then
    #  pushover_push_annotation="Ground Station: ${GROUND_STATION_LOCATION}<br/>"
    #fi
    pushover_push_annotation="${pushover_push_annotation}<b>Start: </b>${capture_start}<br/>"
    pushover_push_annotation="${pushover_push_annotation} <a href=${PUSHOVER_LINK_URL}?pass_id=${pass_id}>BROWSER LINK</a>";
    pushover_push_annotation="${pushover_push_annotation}<b>Gain: </b>${gain}<br/>"
    log "Call pushover script with push_file_list: $push_file_list" "INFO"
    ${PUSH_PROC_DIR}/push_pushover.sh "${pushover_push_annotation}" "${SAT_NAME}" "$push_file_list" >> $NOAA_LOG 2>&1
  fi

  # handle Slack pushing if enabled
  if [ "${ENABLE_SLACK_PUSH}" == "true" ]; then
    ${PUSH_PROC_DIR}/push_slack.sh "${push_annotation} <${SLACK_LINK}?pass_id=${pass_id}>\n" $push_file_list >> $NOAA_LOG 2>&1
  fi

  # handle Twitter pushing if enabled
  if [ "${ENABLE_TWITTER_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Twitter" "INFO"
    ${PUSH_PROC_DIR}/push_twitter.sh "${push_annotation}" $push_file_list >> $NOAA_LOG 2>&1
  fi

  # handle Facebook pushing if enabled
  if [ "${ENABLE_FACEBOOK_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Facebook" "INFO"
    python3 ${PUSH_PROC_DIR}/push_facebook.py "${push_annotation}" "${push_file_list}" >> $NOAA_LOG 2>&1
  fi

  # handle Mastodon pushing if enabled
  if [ "${ENABLE_MASTODON_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Mastodon" "INFO"
    python3 $PUSH_PROC_DIR}/push_mastodon.py "${push_annotation}" ${push_file_list} >> $NOAA_LOG 2>&1
  fi

  # handle Instagram pushing if enabled
  if [ "${ENABLE_INSTAGRAM_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Instagram" "INFO"
    $CONVERT "${IMAGE_FILE_BASE}${suffix}" -resize "1080x1350>" -gravity center -background black -extent 1080x1350 "${IMAGE_FILE_BASE}-instagram.jpg"
    python3 ${PUSH_PROC_DIR}/push_instagram.py "${push_annotation}" $(sed 's|/srv/images/||' <<< "${IMAGE_FILE_BASE}-instagram.jpg") ${WEB_SERVER_NAME} >> $NOAA_LOG 2>&1
    rm "${IMAGE_FILE_BASE}-instagram.jpg"
  fi

  # handle Matrix pushing if enabled
  if [ "${ENABLE_MATRIX_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Matrix" "INFO"
    ${PUSH_PROC_DIR}/push_matrix.sh "${push_annotation}" $push_file_list >> $NOAA_LOG 2>&1
  fi

  # handle email pushing if enabled
  if [ "$ENABLE_EMAIL_PUSH" == "true" ]; then
    log "Emailing images" "INFO"
    for i in $push_file_list
    do
      ${PUSH_PROC_DIR}/push_email.sh "${EMAIL_PUSH_ADDRESS}" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi

  # handle Discord pushing if enabled
  if [ "${ENABLE_DISCORD_PUSH}" == "true" ]; then
    log "Pushing images to Discord" "INFO"
    for i in $push_file_list
    do
      ${PUSH_PROC_DIR}/push_discord.sh "$DISCORD_METEOR_WEBHOOK" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi
else
  log "No ELEKTRO-L3 image received!" "INFO"
fi

# calculate and report total time for capture
rm ${PID_FILE}
log "Deleted PID file ${PID_FILE}" "INFO"
TIMER_END=$(date '+%s')
DIFF=$(($TIMER_END - $TIMER_START))
PROC_TIME=$(date -ud "@$DIFF" +'%H:%M.%S')
log "Total processing time: ${PROC_TIME}" "INFO"
