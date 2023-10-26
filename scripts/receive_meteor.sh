#!/bin/bash
#
# Purpose: Receive and process Meteor-M 2 captures.
#
# Input parameters:
#   1. Name of satellite "METEOR-M 2"
#   2. Filename of image outputs
#   3. TLE file location
#   4. Duration of capture (seconds)
#   5. Max angle elevation for satellite
#   6. Direction of pass
#   7. Side of pass (W=West, E=East) relative to base station
#
# Example:
#   ./receive_meteor.sh "METEOR-M 2" METEOR-M220210205-192623 1612571183 922 39 Northbound W

# time keeping
TIMER_START=$(date '+%s')

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
capture_start="$START_DATE $(date '+%Z')"

# input params
export SAT_NAME=$1
export FILENAME_BASE=$2
export TLE_FILE=$3
export EPOCH_START=$4
export CAPTURE_TIME=$5
export SAT_MAX_ELEVATION=$6
export PASS_DIRECTION=$7
export PASS_SIDE=$8

# export some variables for use in the annotation - note that we do not
# want to export all of .noaa-v2.conf because it contains sensitive info
export GAIN=$METEOR_M2_3_GAIN
export SUN_MIN_ELEV=$METEOR_M2_3_SUN_MIN_ELEV
export SDR_DEVICE_ID=$METEOR_M2_3_SDR_DEVICE_ID
export BIAS_TEE=$METEOR_M2_3_ENABLE_BIAS_TEE
export FREQ_OFFSET=$METEOR_M2_3_FREQ_OFFSET
export SAT_MIN_ELEV=$METEOR_M2_3_SAT_MIN_ELEV

# base directory plus filename_base for re-use
RAMFS_AUDIO_BASE="${RAMFS_AUDIO}/${FILENAME_BASE}"
AUDIO_FILE_BASE="${METEOR_AUDIO_OUTPUT}/${FILENAME_BASE}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME_BASE}"
IMAGE_THUMB_BASE="${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}"

case "$RECEIVER_TYPE" in
     "rtlsdr")
         samplerate="1.024e6"
         receiver="rtlsdr"
         decimation=8
         ;;
     "airspy_mini")
         samplerate="3e6"
         receiver="airspy"
         decimation=25
         ;;
     "airspy_r2")
         samplerate="2.5e6"
         receiver="airspy"
         decimation=20
         ;;
     "hackrf")
         samplerate="4e6"
         receiver="hackrf"
         decimation=32
         ;;
     "sdrplay")
         samplerate="2e6"
         receiver="sdrplay"
         decimation=16
         ;;
     "mirisdr")
         samplerate="1e6"
         receiver="sdrplay"
         decimation=25
         ;;
     *)
         echo "Invalid RECEIVER_TYPE value: $RECEIVER_TYPE"
         exit 1
         ;;
esac

if [ "$SAT_NAME" == "METEOR-M2 3" ]; then
  SAT_NUMBER="M2_3"
elif [ "$SAT_NAME" == "METEOR-M2 4" ]; then
  SAT_NUMBER="M2_4"
fi

mode="$([[ "$METEOR_${SAT_NUMBER}_80K_INTERLEAVING" == "true" ]] && echo "_80k" || echo "")"

gain_option=""
if [[ "$receiver" == "rtlsdr" ]]; then
  gain_option="--source_id $SDR_DEVICE_ID --gain"
else
  gain_option="--general_gain"
fi

if [ "$BIAS_TEE" == "-T" ]; then
    bias_tee_option="--bias"
else
    bias_tee_option=""
fi

# check if there is enough free memory to store pass on RAM
FREE_MEMORY=$(free -m | grep Mem | awk '{print $7}')
if [ "$FREE_MEMORY" -lt $METEOR_M2_MEMORY_THRESHOLD ]; then
  log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
  log "Free : ${FREE_MEMORY} ; Required : ${METEOR_M2_MEMORY_THRESHOLD}" "INFO"
  RAMFS_AUDIO_BASE="${AUDIO_FILE_BASE}"
  in_mem=false
else
  log "The system has enough space to store a Meteor pass on RAM" "INFO"
  log "Free : ${FREE_MEMORY} ; Required : ${METEOR_M2_MEMORY_THRESHOLD}" "INFO"
  in_mem=true
fi

FLIP=""
log "Direction $PASS_DIRECTION" "INFO"
if [ "$PASS_DIRECTION" == "Northbound" ] && [ "$FLIP_METEOR_IMG" == "true" ]; then
  log "I'll flip this image pass because FLIP_METEOR_IMG is set to true and PASS_DIRECTION is Northbound" "INFO"
  FLIP="-rotate 180"
fi

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
export SUN_ELEV=$(python3 "$SCRIPTS_DIR"/tools/sun.py "$PASS_START")

# determine if pass is in daylight
daylight=0
if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then daylight=1; fi

# TODO: Fix this up - this conditional selection is a massive bit of complexity that
#       needs to be handled, but in the interest of not breaking everything (at least in
#       the first round), keeping it simple.
push_file_list=""
spectrogram=0
polar_az_el=0
polar_direction=0

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

log "Recording ${NOAA_HOME} via $receiver at ${METEOR_M2_3_FREQ} MHz using SatDump record " "INFO"
audio_temporary_storage_directory="$(dirname "${RAMFS_FILE_BASE}")"
$SATDUMP live meteor_m2-x_lrpt${mode} "$audio_temporary_storage_directory" --source $receiver --samplerate $samplerate --frequency "${METEOR_M2_3_FREQ}e6" $gain_option $GAIN $bias_tee_option --timeout $CAPTURE_TIME >> $NOAA_LOG 2>&1
rm satdump.log
mv "$audio_temporary_storage_directory/meteor_m2-x_lrpt${mode}.cadu" "${RAMFS_AUDIO_BASE}.cadu"

if [[ "$METEOR_DECODER" == "meteordemod" ]]; then
  log "Removing old bmp and gcp files" "INFO"
  find "$NOAA_HOME/tmp/meteor" -type f \( -name "*.gcp" -o -name "*.bmp" \) -mtime +1 -delete >> $NOAA_LOG 2>&1

  # if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  #   log "Producing spectrogram" "INFO"
  #   spectrogram=1
  #   spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
  #   ${IMAGE_PROC_DIR}/spectrogram.sh "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" "${spectro_text}" >> $NOAA_LOG 2>&1
  #   ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png" >> $NOAA_LOG 2>&1
  # fi

  log "Running MeteorDemod to demodulate OQPSK file, rectify (spread) images, create heat map and composites and convert them to JPG" "INFO"
  if [[ "$METEOR_${SAT_NUMBER}_80K_INTERLEAVING" == "true" ]]; then
    $METEORDEMOD -m oqpsk -diff 1 -int 1 -s 80000 -sat METEOR-M-2-3 -t "$TLE_FILE" -f jpg -i "${RAMFS_AUDIO_BASE}.cadu" -o "$NOAA_HOME/tmp/meteor"  >> $NOAA_LOG 2>&1
  else
    $METEORDEMOD -m oqpsk -diff 1 -s 72000 -sat METEOR-M-2-3 -t "$TLE_FILE" -f jpg -i "${RAMFS_AUDIO_BASE}.cadu" -o "$NOAA_HOME/tmp/meteor" >> $NOAA_LOG 2>&1
  fi

  log "Waiting for files to close" "INFO"
  sleep 2

  for i in -o $NOAA_HOME/tmp/meteor/spread_*.jpg; do
    $CONVERT -quality 100 $FLIP "$i" "$i" >> $NOAA_LOG 2>&1
  done

  for file in $NOAA_HOME/tmp/meteor/*.jpg; do
    new_filename=$(echo "$file" | sed -E 's/_([0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+)//')        #This part removes unecessary numbers from the MeteorDemod image names using RegEx
    mv "$file" "$new_filename"
    image_filename=$(basename "$new_filename")

    ${IMAGE_PROC_DIR}/meteor_normalize_annotate.sh "$new_filename" "${IMAGE_FILE_BASE}-${image_filename%.jpg}.jpg" $METEOR_IMAGE_QUALITY >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-${image_filename%.jpg}.jpg" "${IMAGE_THUMB_BASE}-${image_filename%.jpg}.jpg" >> $NOAA_LOG 2>&1
    rm "$new_filename"
    push_file_list="$push_file_list ${IMAGE_FILE_BASE}-${image_filename%.jpg}.jpg"
  done

  if [ "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES}" == "true" ]; then
    log "Contributing images for creating community composites" "INFO"
    curl -F "file=@${RAMFS_AUDIO_BASE}.cadu" "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES_URL}/meteor" >> $NOAA_LOG 2>&1
  fi

  if [ "$DELETE_METEOR_AUDIO" == true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO_BASE}.cadu"
  else
    if [ "$in_mem" == "true" ]; then
      log "Moving audio files out to the SD card" "INFO"
      mv "${RAMFS_AUDIO_BASE}.cadu" "${AUDIO_FILE_BASE}.cadu"
      log "Deleting Meteor audio files older than $DELETE_FILES_OLDER_THAN_DAYS days" "INFO"
      find /srv/audio/meteor -type f \( -name "*.wav" -o -name "*.s" -o -name "*.cadu" -o -name "*.gcp" -o -name "*.bmp" \) -mtime +${DELETE_FILES_OLDER_THAN_DAYS} -delete >> $NOAA_LOG 2>&1
    fi
  fi
elif [[ "$METEOR_DECODER" == "satdump" ]]; then

  $SATDUMP meteor_m2-x_lrpt${mode} cadu "${RAMFS_AUDIO_BASE}.cadu" . >> $NOAA_LOG 2>&1
  rm satdump.log

  find MSU-MR/ -type f ! -name "*projected*" ! -name "*corrected*" -delete

  log "Deleting SatDump projected composites which have been generated, but the channels aren't broadcast" "INFO"
  for projected_file in MSU-MR/rgb_msu_mr_rgb_*_projected.png; do
      # Extract the corresponding corrected.png filename
      corrected_file="${projected_file/rgb_msu_mr_rgb_/msu_mr_rgb_}"
      corrected_file="${corrected_file/_projected.png/_corrected.png}"

      # Check if the corrected.png file does not exist
      if [ ! -e "$corrected_file" ]; then
          log "$corrected_file doesn't exist, hence deleting $projected_file" "INFO"
          rm "$projected_file"
      fi
  done

  log "Removing images without a map if they exist" "INFO"
  for file in MSU-MR/*map.png; do
    mv "$file" "${file/_map.png/.png}"
  done

  for i in MSU-MR/*_corrected.png
  do
    $CONVERT "$i" $FLIP "$i" >> $NOAA_LOG 2>&1
  done

    # Renaming files, annotating images, and creating thumbnails
  for i in MSU-MR/*.png; do
    path="$(pwd)"
    image_filename=$(basename "$i")
    new_name="$image_filename"

    # Use parameter expansion to remove the specified prefixes
    new_name="${new_name#msu_mr_rgb_}"
    new_name="${new_name#rgb_msu_mr_rgb_}"
    new_name="${new_name#rgb_msu_mr_rgb_}"
    new_name="${new_name#rgb_msu_mr_}"
    new_name="${new_name#msu_mr_}"

    # Rename the file with the new name
    mv "$i" "$path/MSU-MR/$new_name" >> $NOAA_LOG 2>&1

    log "Annotating images and creating thumbnails" "INFO"
    ${IMAGE_PROC_DIR}/meteor_normalize_annotate.sh "$path/MSU-MR/$new_name" "${IMAGE_FILE_BASE}-${new_name%.png}.jpg" $METEOR_IMAGE_QUALITY >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-${new_name%.png}.jpg" "${IMAGE_THUMB_BASE}-${new_name%.png}.jpg" >> $NOAA_LOG 2>&1
    rm "$path/MSU-MR/$new_name" >> $NOAA_LOG 2>&1
    push_file_list="$push_file_list ${IMAGE_FILE_BASE}-${new_name%.png}.jpg"
  done
  rm -r MSU-MR >> $NOAA_LOG 2>&1

  if [ "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES}" == "true" ]; then
    log "Contributing images for creating community composites" "INFO"
    curl -F "file=@${RAMFS_AUDIO_BASE}.cadu" "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES_URL}/meteor" >> $NOAA_LOG 2>&1
  fi

  if [ "$DELETE_METEOR_AUDIO" == true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO_BASE}.cadu"
  else
    if [ "$in_mem" == "true" ]; then
      log "Moving CADU files out to the SD card" "INFO"
      mv "${RAMFS_AUDIO_BASE}.cadu" "${AUDIO_FILE_BASE}.cadu" >> $NOAA_LOG 2>&1
      log "Deleting Meteor audio files older than $DELETE_FILES_OLDER_THAN_DAYS days" "INFO"
      find /srv/audio/meteor -type f \( -name "*.wav" -o -name "*.s" -o -name "*.cadu" -o -name "*.gcp" -o -name "*.bmp" \) -mtime +${DELETE_FILES_OLDER_THAN_DAYS} -delete >> $NOAA_LOG 2>&1
    fi
  fi
else
    echo "Unknown decoder: $METEOR_DECODER"
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [ -n "$(find /srv/images -maxdepth 1 -type f -name "$(basename "$IMAGE_FILE_BASE")*.jpg" -print -quit)" ]; then

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
  push_annotation="${push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
  push_annotation="${push_annotation} Sun Elevation: ${SUN_ELEV}°"
  push_annotation="${push_annotation} Gain: ${gain}"
  push_annotation="${push_annotation} | ${PASS_DIRECTION}"

  meteor_suffixes=(
      '-321_corrected.jpg'
      '-321_projected.jpg'
      '-equidistant_321.jpg'
      '-mercator_321.jpg'
      '-spread_321.jpg'
      '-spread_123.jpg'
      '-221_corrected.jpg'
      '-221_projected.jpg'
      '-equidistant_221.jpg'
      '-mercator_321.jpg'
      '-spread_221.jpg'
      '-equidistant_654.jpg'
      '-mercator_654.jpg'
      '-spread_654.jpg'
      '-Thermal_Channel_corrected.jpg'
      '-equidistant_IR.jpg'
      '-mercator_IR.jpg'
      '-spread_IR.jpg'
  )

  # Iterate through the meteor_suffixes array
  for suffix in "${meteor_suffixes[@]}"; do
      if [[ -f "${IMAGE_THUMB_BASE}${suffix}" ]]; then
          cp "${IMAGE_THUMB_BASE}${suffix}" "${IMAGE_THUMB_BASE}-website-thumbnail.jpg"
          break
      fi
  done

  log "Some images were produced, let's push them to the database and social media" "INFO"
  if [[ "${PRODUCE_POLAR_AZ_EL}" == "true" ]]; then
    log "Producing polar graph of azimuth and elevation for pass" "INFO"
    polar_az_el=1
    epoch_end=$((EPOCH_START + CAPTURE_TIME))
    ${IMAGE_PROC_DIR}/polar_plot.py "${SAT_NAME}" \
                                    "${TLE_FILE}" \
                                    $EPOCH_START \
                                    $epoch_end \
                                    $LAT \
                                    $LON \
                                    $SAT_MIN_ELEV \
                                    $PASS_DIRECTION \
                                    "${IMAGE_FILE_BASE}-polar-azel.jpg" \
                                    "azel"
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-azel.jpg" "${IMAGE_THUMB_BASE}-polar-azel.jpg"
  fi

  polar_direction=0
  if [[ "${PRODUCE_POLAR_DIRECTION}" == "true" ]]; then
    log "Producing polar graph of direction for pass" "INFO"
    polar_direction=1
    epoch_end=$((EPOCH_START + CAPTURE_TIME))
    ${IMAGE_PROC_DIR}/polar_plot.py "${SAT_NAME}" \
                                    "${TLE_FILE}" \
                                    $EPOCH_START \
                                    $epoch_end \
                                    $LAT \
                                    $LON \
                                    $SAT_MIN_ELEV \
                                    $PASS_DIRECTION \
                                    "${IMAGE_FILE_BASE}-polar-direction.png" \
                                    "direction"
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-direction.png" "${IMAGE_THUMB_BASE}-polar-direction.png"
  fi

  # check if we got an image, and post-process if so

  log "I got a successful jpg images" "INFO"

  # insert or replace in case there was already an insert due to the spectrogram creation
  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram, has_polar_az_el, has_polar_direction, gain) \
                                      VALUES ($EPOCH_START, \"$FILENAME_BASE\", $daylight, 0, $spectrogram, $polar_az_el, $polar_direction, $GAIN);" >> $NOAA_LOG 2>&1

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


  # handle Pushover pushing if enabled
  if [ "${ENABLE_PUSHOVER_PUSH}" == "true" ]; then
    pushover_push_annotation=""
    #if [ "${GROUND_STATION_LOCATION}" != "" ]; then
    #  pushover_push_annotation="Ground Station: ${GROUND_STATION_LOCATION}<br/>"
    #fi
    pushover_push_annotation="${pushover_push_annotation}<b>Start: </b>${capture_start}<br/>"
    pushover_push_annotation="${pushover_push_annotation}<b>Max Elev: </b>${SAT_MAX_ELEVATION}° ${PASS_SIDE}<br/>"
    #pushover_push_annotation="${pushover_push_annotation}<b>Sun Elevation: </b>${SUN_ELEV}°<br/>"
    #pushover_push_annotation="${pushover_push_annotation}<b>Gain: </b>${gain} | ${PASS_DIRECTION}<br/>"
    pushover_push_annotation="${pushover_push_annotation} <a href=${PUSHOVER_LINK_URL}?pass_id=${pass_id}>BROWSER LINK</a>";

    log "Call pushover script with push_file_list: $push_file_list" "INFO"
    ${PUSH_PROC_DIR}/push_pushover.sh "${pushover_push_annotation}" "${SAT_NAME}" "$push_file_list"
  fi

  # handle Slack pushing if enabled
  if [ "${ENABLE_SLACK_PUSH}" == "true" ]; then
    ${PUSH_PROC_DIR}/push_slack.sh "${push_annotation} <${SLACK_LINK}?pass_id=${pass_id}>\n" $push_file_list
  fi

  # handle twitter pushing if enabled
  if [ "${ENABLE_TWITTER_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Twitter" "INFO"
    ${PUSH_PROC_DIR}/push_twitter.sh "${push_annotation}" $push_file_list
  fi

  # handle facebook pushing if enabled
  if [ "${ENABLE_FACEBOOK_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Facebook" "INFO"
    ${PUSH_PROC_DIR}/push_facebook.py "${push_annotation}" "${push_file_list}"
  fi

  # handle instagram pushing if enabled
  if [ "${ENABLE_INSTAGRAM_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Instagram" "INFO"
    $CONVERT "${IMAGE_FILE_BASE}${suffix}" -resize "1080x1350>" -gravity center -background black -extent 1080x1350 "${IMAGE_FILE_BASE}-instagram.jpg"
    ${PUSH_PROC_DIR}/push_instagram.py "${push_annotation}" $(sed 's|/srv/images/||' <<< "${IMAGE_FILE_BASE}-instagram.jpg") ${WEB_SERVER_NAME}
    rm "${IMAGE_FILE_BASE}-instagram.jpg"
  fi

  # handle matrix pushing if enabled
  if [ "${ENABLE_MATRIX_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Matrix" "INFO"
    ${PUSH_PROC_DIR}/push_matrix.sh "${push_annotation}" $push_file_list
  fi

  if [ "$ENABLE_EMAIL_PUSH" == "true" ]; then
    log "Emailing images" "INFO"
    for i in $push_file_list
    do
      ${PUSH_PROC_DIR}/push_email.sh "${EMAIL_PUSH_ADDRESS}" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi

  if [ "${ENABLE_DISCORD_PUSH}" == "true" ]; then
    log "Pushing images to Discord" "INFO"
    for i in $push_file_list
    do
      ${PUSH_PROC_DIR}/push_discord.sh "$DISCORD_METEOR_WEBHOOK" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi
else
  log "No images found, not pushing anything" "INFO"
fi

# calculate and report total time for capture
TIMER_END=$(date '+%s')
DIFF=$(($TIMER_END - $TIMER_START))
PROC_TIME=$(date -ud "@$DIFF" +'%H:%M.%S')
log "Total processing time: ${PROC_TIME}" "INFO"
