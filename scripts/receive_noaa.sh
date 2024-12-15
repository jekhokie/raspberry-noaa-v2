#!/bin/bash
#
# Purpose: Receive and process NOAA captures.
#
# Input parameters:
#   1. Name of satellite (e.g. "NOAA 18")
#   2. Filename of image outputs
#   3. TLE file location
#   4. Epoch start time for capture
#   5. Duration of capture (seconds)
#   6. Max angle elevation for satellite
#   7. Direction of pass
#   8. Side of pass (W=West, E=East) relative to base station
#
# Example:
#   ./receive_noaa.sh "NOAA 18" NOAA1820210208-194829 ./orbit.tle 1612831709 919 31 Southbound E

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
if [ "$SAT_NAME" == "NOAA 15" ]; then
  export GAIN=$NOAA_15_GAIN
  export SUN_MIN_ELEV=$NOAA_15_SUN_MIN_ELEV
  export SDR_DEVICE_ID=$NOAA_15_SDR_DEVICE_ID
  export BIAS_TEE=$NOAA_15_ENABLE_BIAS_TEE
  export FREQ_OFFSET=$NOAA_15_FREQ_OFFSET
  export SAT_MIN_ELEV=$NOAA_15_SAT_MIN_ELEV
  SAT_NUMBER=15
  NOAA_FREQUENCY=$NOAA15_FREQ
elif [ "$SAT_NAME" == "NOAA 18" ]; then
  export GAIN=$NOAA_18_GAIN
  export SUN_MIN_ELEV=$NOAA_18_SUN_MIN_ELEV
  export SDR_DEVICE_ID=$NOAA_18_SDR_DEVICE_ID
  export BIAS_TEE=$NOAA_18_ENABLE_BIAS_TEE
  export FREQ_OFFSET=$NOAA_18_FREQ_OFFSET
  export SAT_MIN_ELEV=$NOAA_18_SAT_MIN_ELEV
  SAT_NUMBER=18
  NOAA_FREQUENCY=$NOAA18_FREQ
elif [ "$SAT_NAME" == "NOAA 19" ]; then
  export GAIN=$NOAA_19_GAIN
  export SUN_MIN_ELEV=$NOAA_19_SUN_MIN_ELEV
  export SDR_DEVICE_ID=$NOAA_19_SDR_DEVICE_ID
  export BIAS_TEE=$NOAA_19_ENABLE_BIAS_TEE
  export FREQ_OFFSET=$NOAA_19_FREQ_OFFSET
  export SAT_MIN_ELEV=$NOAA_19_SAT_MIN_ELEV
  SAT_NUMBER=19
  NOAA_FREQUENCY=$NOAA19_FREQ
fi

# base directory plus filename helper variables
RAMFS_AUDIO_BASE="${RAMFS_AUDIO}/${FILENAME_BASE}"
AUDIO_FILE_BASE="${NOAA_AUDIO_OUTPUT}/${FILENAME_BASE}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME_BASE}"
IMAGE_THUMB_BASE="${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}"

# check if there is enough free memory to store pass on RAM
FREE_MEMORY=$(free -m | grep Mem | awk '{print $7}')
if [ "$FREE_MEMORY" -lt $NOAA_MEMORY_THRESHOLD ]; then
  log "The system doesn't have enough space to store a NOAA pass on RAM" "INFO"
  log "Free : ${FREE_MEMORY} ; Required : ${NOAA_MEMORY_THRESHOLD}" "INFO"
  RAMFS_AUDIO_BASE="${AUDIO_FILE_BASE}"
  in_mem=false
else
  log "The system has enough space to store a NOAA pass on RAM" "INFO"
  log "Free : ${FREE_MEMORY} ; Required : ${NOAA_MEMORY_THRESHOLD}" "INFO"
  in_mem=true
fi

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
         receiver="airspyhf"
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
  ppm_correction="--ppm_correction"
else
  gain_option="--general_gain"
  FREQ_OFFSET=""
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

if [ "$NOAA_DECODER" == "satdump" ]; then
  finish_processing="--finish_processing"
else
  finish_processing=""
fi

FLIP=""
log "Direction $PASS_DIRECTION" "INFO"
if [ "$PASS_DIRECTION" == "Northbound" ]; then
  log "I'll flip this image pass because PASS_DIRECTION is Northbound" "INFO"
  FLIP="-rotate 180"
fi

crop_topbottom=""
if [ "$NOAA_CROP_TOPTOBOTTOM" == "true" ]; then
  log "Cropping SatDump NOAA images enabled" "INFO"
  crop_topbottom="--autocrop_wedges"
fi

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
export SUN_ELEV=$(python3 "$SCRIPTS_DIR"/tools/sun.py "$PASS_START")

# run all enhancements all the time - any that cannot be produced will
# simply be left out/not included, so there is no harm in running all of them
daylight=$((SUN_ELEV > SUN_MIN_ELEV ? 1 : 0))

#start capture
log "Recording ${NOAA_HOME} via ${RECEIVER_TYPE} at ${freq} MHz via SatDump live pipeline" "INFO"
audio_temporary_storage_directory="$(dirname "${RAMFS_FILE_BASE}")"
log "$SATDUMP live noaa_apt $audio_temporary_storage_directory --source $receiver --samplerate $samplerate $ppm_correction ${FREQ_OFFSET} --frequency "${NOAA_FREQUENCY}e6" --satellite_number ${SAT_NUMBER} --sdrpp_noise_reduction $sdr_id_option $SDR_DEVICE_ID $gain_option $GAIN $bias_tee_option $crop_topbottom --start_timestamp $PASS_START --save_wav $finish_processing --timeout $CAPTURE_TIME" "INFO"
$SATDUMP live noaa_apt $audio_temporary_storage_directory --source $receiver --samplerate $samplerate $ppm_correction ${FREQ_OFFSET} --frequency "${NOAA_FREQUENCY}e6" --satellite_number ${SAT_NUMBER} --sdrpp_noise_reduction $sdr_id_option $SDR_DEVICE_ID $gain_option $GAIN $bias_tee_option $crop_topbottom --start_timestamp $PASS_START --save_wav $finish_processing --timeout $CAPTURE_TIME >> $NOAA_LOG 2>&1
rm "$audio_temporary_storage_directory/dataset.json" "$audio_temporary_storage_directory/product.cbor" >> $NOAA_LOG 2>&1
log "Files recorded" "INFO"

if [ "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES}" == "true" ]; then
  log "Contributing images for creating community composites" "INFO"
  curl -F "file=@${RAMFS_AUDIO_BASE}.wav" "${CONTRIBUTE_TO_COMMUNITY_COMPOSITES_URL}/noaa" >> $NOAA_LOG 2>&1
fi

if [ "$NOAA_DECODER" == "wxtoimg" ]; then
  log "Resampling down audio" "INFO"
  $SOX "$audio_temporary_storage_directory/noaa_apt.wav" -r 11025 "${RAMFS_AUDIO_BASE}.wav" pad 0 $WXTOIMG_MAP_OFFSET >> $NOAA_LOG 2>&1
  rm "$audio_temporary_storage_directory/noaa_apt.wav" >> $NOAA_LOG 2>&1

  push_file_list=""
  #generate outputs
  spectrogram=0
  if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
    log "Producing spectrogram" "INFO"
    spectrogram=1
    spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
    ${IMAGE_PROC_DIR}/spectrogram.sh "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" "${spectro_text}" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png" >> $NOAA_LOG 2>&1
  fi

  pristine=0
  if [[ "${PRODUCE_NOAA_PRISTINE}" == "true" ]]; then
    log "Producing pristine image" "INFO"
    pristine=1
    ${IMAGE_PROC_DIR}/noaa_pristine.sh "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-pristine.png" 2>&1 | grep -Ev "invalid pointer|Aborted" >> $NOAA_LOG
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-pristine.png" "${IMAGE_THUMB_BASE}-pristine.png" >> $NOAA_LOG 2>&1
    push_file_list="${push_file_list} ${IMAGE_FILE_BASE}-pristine.png"
  fi

  histogram=0
  if [ "${PRODUCE_NOAA_PRISTINE_HISTOGRAM}" == "true" ]; then
    tmp_dir="${NOAA_HOME}/tmp"
    histogram=1
    histogram_text="${capture_start} @ ${SAT_MAX_ELEVATION}° Gain: ${GAIN}"

    log "Generating Data for Histogram" "INFO"
    ${IMAGE_PROC_DIR}/noaa_histogram_data.sh "${RAMFS_AUDIO_BASE}.wav" "${tmp_dir}/${FILENAME_BASE}-a.png" "${tmp_dir}/${FILENAME_BASE}-b.png"  2>&1 | grep -Ev "invalid pointer|Aborted" >> $NOAA_LOG

    # Define channel names
    channels=("a" "b")

    # Loop through channels
    for channel in "${channels[@]}"; do
      log "Producing histogram of NOAA pristine image channel $channel" "INFO"
      ${IMAGE_PROC_DIR}/histogram.sh "${tmp_dir}/${FILENAME_BASE}-${channel}.png" "${IMAGE_FILE_BASE}-histogram-${channel}.jpg" "${SAT_NAME} - Channel $channel" "${histogram_text}" >> $NOAA_LOG 2>&1
      ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-histogram-${channel}.jpg" "${IMAGE_THUMB_BASE}-histogram-${channel}.jpg" >> $NOAA_LOG 2>&1
    done

    log "Horizontally Merge two Histogram Channels to a single image for output"
    $CONVERT +append "${IMAGE_FILE_BASE}-histogram-a.jpg" "${IMAGE_FILE_BASE}-histogram-b.jpg" -resize x500 "${IMAGE_FILE_BASE}-histogram.jpg" >>$NOAA_LOG 2>&1
    $CONVERT +append "${IMAGE_THUMB_BASE}-histogram-a.jpg" "${IMAGE_THUMB_BASE}-histogram-b.jpg" -resize x300 "${IMAGE_THUMB_BASE}-histogram.jpg" >>$NOAA_LOG 2>&1

    # Remove temporary files
    for channel in "${channels[@]}"; do
      rm "${IMAGE_FILE_BASE}-histogram-${channel}.jpg" "${IMAGE_THUMB_BASE}-histogram-${channel}.jpg" "${tmp_dir}/${FILENAME_BASE}-${channel}.png"
    done
  fi

  log "Bulding pass map" "INFO"
  # add 10 seconds to ensure we account for small deviations in timing - being even a second too soon
  # can cause an error of "wxmap: warning: could not find matching pass to build overlay map.", while
  # going over the start time by a few seconds while still being within the pass timing causes wxmap
  # to track *back* to the start of the pass
  epoch_adjusted=$(($PASS_START + 10))

  extra_map_opts=""
  [[ "${NOAA_MAP_CROSSHAIR_ENABLE}" == "true" ]] && extra_map_opts+=" -l 1 -c l:${NOAA_MAP_CROSSHAIR_COLOR}" || extra_map_opts+=" -l 0"
  [[ "${NOAA_MAP_GRID_DEGREES}" != "0.0" ]] && extra_map_opts+=" -g ${NOAA_MAP_GRID_DEGREES} -c g:${NOAA_MAP_GRID_COLOR}" || extra_map_opts+=" -g 0.0"
  [[ "${NOAA_MAP_COUNTRY_BORDER_ENABLE}" == "true" ]] && extra_map_opts+=" -C 1 -c C:${NOAA_MAP_COUNTRY_BORDER_COLOR}" || extra_map_opts+=" -C 0"
  [[ "${NOAA_MAP_STATE_BORDER_ENABLE}" == "true" ]] && extra_map_opts+=" -S 1 -c S:${NOAA_MAP_STATE_BORDER_COLOR}" || extra_map_opts+=" -S 0"

  map_overlay="${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"
  $WXMAP -T "${SAT_NAME}" -H "${TLE_FILE}" -p 0 ${extra_map_opts} -o "${epoch_adjusted}" "$map_overlay" 2>&1 | grep -Ev "invalid pointer|Aborted" >> "$NOAA_LOG"

  if [ "$daylight" -eq 1 ]; then
    ENHANCEMENTS="${NOAA_DAY_ENHANCEMENTS}"
  else
    ENHANCEMENTS="${NOAA_NIGHT_ENHANCEMENTS}"
  fi

  # build images based on enhancements defined
  log "Normalizing and annotating NOAA images" "INFO"
  for enhancement in $ENHANCEMENTS; do
    export ENHANCEMENT=$enhancement
    log "Decoding image" "INFO"

    if [ $enhancement == "enhanced-IR" ]; then
      continue
    elif [ $enhancement == "avi" ]; then
      ${IMAGE_PROC_DIR}/noaa_avi.sh $map_overlay "${RAMFS_AUDIO_BASE}.wav" 2>&1 | grep -Ev "invalid pointer|Aborted" >> $NOAA_LOG
    else
      ${IMAGE_PROC_DIR}/noaa_enhancements.sh $map_overlay "${RAMFS_AUDIO_BASE}.wav" "${IMAGE_FILE_BASE}-$enhancement.jpg" $enhancement 2>&1 | grep -Ev "invalid pointer|Aborted" >> $NOAA_LOG 
    fi

    if [ -f "${IMAGE_FILE_BASE}-$enhancement.jpg" ]; then
      ${IMAGE_PROC_DIR}/noaa_normalize_annotate.sh "${IMAGE_FILE_BASE}-$enhancement.jpg" "${IMAGE_FILE_BASE}-$enhancement.jpg" $NOAA_IMAGE_QUALITY 2>&1 | grep -Ev "invalid pointer|Aborted" >> $NOAA_LOG
      ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-$enhancement.jpg" "${IMAGE_THUMB_BASE}-$enhancement.jpg" >> $NOAA_LOG 2>&1
      push_file_list="${push_file_list} ${IMAGE_FILE_BASE}-$enhancement.jpg"
    fi
  done

  rm $map_overlay >> $NOAA_LOG 2>&1

  if [ "$DELETE_NOAA_AUDIO" == true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO_BASE}.wav"
  else
    if [ "$in_mem" == "true" ]; then
      log "Moving audio files out to the SD card" "INFO"
      mv "${RAMFS_AUDIO_BASE}.wav" "${AUDIO_FILE_BASE}.wav"
      log "Deleting NOAA audio files older than $DELETE_FILES_OLDER_THAN_DAYS days" "INFO"
      find /srv/audio/noaa -type f -name "*.wav" -mtime +${DELETE_FILES_OLDER_THAN_DAYS} -delete >> $NOAA_LOG 2>&1
    fi
  fi
elif [ "$NOAA_DECODER" == "satdump" ]; then
  log "Resampling down audio" "INFO"
  $SOX "$audio_temporary_storage_directory/noaa_apt.wav" -r 11025 "${RAMFS_AUDIO_BASE}.wav" >> $NOAA_LOG 2>&1
  rm "$audio_temporary_storage_directory/noaa_apt.wav" >> $NOAA_LOG 2>&1

  spectrogram=0
  pristine=0
  histogram=0

  if [ -n "$(find . -maxdepth 1 -type f -name '*.png')" ]; then
    log "Removing images without a map if they exist" "INFO"
    for file in *map.png; do
      mv "$file" "${file/_map.png/.png}"
    done

    log "Flipping projected images once here and renaming them so they will be flipped again later in the for loop restoring their original orientation" "INFO"
    for projected_file in rgb_*.png; do
      $CONVERT $projected_file $FLIP $projected_file
    done

    log "Normalizing and annotating NOAA images" "INFO"
    for i in *.png; do
      $CONVERT "$i" $FLIP "$i"

      new_file="${i//_\(Uncalibrated\)}"

      #This if statement should execute only if the $i variable contains the substring _(Uncalibrated), otherwise it doesn't have any point
      if [[ "$i" =~ _\(Uncalibrated\) ]]; then
        if [ ! -f "$new_file" ]; then
          log "Keep using calibrated versions of MCIR and MSA images" "INFO"
          mv "$i" "$new_file"
        else
          log "Delete uncalibrated MCIR and MSA images if calibrated versions exist" "INFO"
          rm "$i"
          continue
        fi
      fi

      new_name="${new_file//rgb_avhrr_3_rgb_}"
      new_name="${new_name//avhrr_apt_rgb_}"
      new_name="${new_name//avhrr_3_rgb_}"
      new_name="${new_name//avhrr_apt_}"
      new_name="${new_name//_enhancement}"
      new_name="${new_name//_\(channel_1\)}"
      new_name="${new_name//_\(channel_4\)}"
      ${IMAGE_PROC_DIR}/noaa_normalize_annotate.sh "$new_file" "${IMAGE_FILE_BASE}-${new_name%.png}.jpg" $NOAA_IMAGE_QUALITY >> $NOAA_LOG 2>&1
      ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-${new_name%.png}.jpg" "${IMAGE_THUMB_BASE}-${new_name%.png}.jpg" >> $NOAA_LOG 2>&1
      push_file_list="${push_file_list} ${IMAGE_FILE_BASE}-${new_name%.png}.jpg"
      rm $new_file >> $NOAA_LOG 2>&1
    done
  fi

  if [ "$DELETE_NOAA_AUDIO" == true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO_BASE}.wav"
  else
    if [ "$in_mem" == "true" ]; then
      log "Moving audio files out to the SD card" "INFO"
      mv "${RAMFS_AUDIO_BASE}.wav" "${AUDIO_FILE_BASE}.wav"
      log "Deleting NOAA audio files older than $DELETE_FILES_OLDER_THAN_DAYS days" "INFO"
      find /srv/audio/noaa -type f -name "*.wav" -mtime +${DELETE_FILES_OLDER_THAN_DAYS} -delete >> $NOAA_LOG 2>&1
    fi
  fi
else
  log "Invalid NOAA_DECODER value: $NOAA_DECODER" "INFO"
  exit 1
fi

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

if [ -n "$(find /srv/images -maxdepth 1 -type f -name "$(basename "$IMAGE_FILE_BASE")*.jpg" -print -quit)" ]; then

  polar_az_el=0
  if [[ "${PRODUCE_POLAR_AZ_EL}" == "true" ]]; then
    log "Producing polar graph of azimuth and elevation for pass" "INFO"
    polar_az_el=1
    epoch_end=$((EPOCH_START + CAPTURE_TIME))
    python3 ${IMAGE_PROC_DIR}/polar_plot.py "${SAT_NAME}" \
                                            "${TLE_FILE}" \
                                            $EPOCH_START \
                                            $epoch_end \
                                            $LAT \
                                            $LON \
                                            $SAT_MIN_ELEV \
                                            $PASS_DIRECTION \
                                            "${IMAGE_FILE_BASE}-polar-azel.jpg" \
                                            "azel" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-azel.jpg" "${IMAGE_THUMB_BASE}-polar-azel.jpg" >> $NOAA_LOG 2>&1
  fi

  polar_direction=0
  if [[ "${PRODUCE_POLAR_DIRECTION}" == "true" ]]; then
    log "Producing polar graph of direction for pass" "INFO"
    polar_direction=1
    epoch_end=$((EPOCH_START + CAPTURE_TIME))
    python3 ${IMAGE_PROC_DIR}/polar_plot.py "${SAT_NAME}" \
                                            "${TLE_FILE}" \
                                            $EPOCH_START \
                                            $epoch_end \
                                            $LAT \
                                            $LON \
                                            $SAT_MIN_ELEV \
                                            $PASS_DIRECTION \
                                            "${IMAGE_FILE_BASE}-polar-direction.png" \
                                            "direction" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-direction.png" "${IMAGE_THUMB_BASE}-polar-direction.png" >> $NOAA_LOG 2>&1
  fi

  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (id, pass_start, file_path, daylight_pass, sat_type, has_spectrogram, has_pristine, has_polar_az_el, has_polar_direction, has_histogram, gain) \
                                      VALUES ( \
                                        (SELECT id FROM decoded_passes WHERE pass_start = $EPOCH_START), \
                                        $EPOCH_START, \"$FILENAME_BASE\", $daylight, 1, $spectrogram, $pristine, $polar_az_el, $polar_direction, $histogram, $GAIN \
                                      );" >> $NOAA_LOG 2>&1

  pass_id=$($SQLITE3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;") >> $NOAA_LOG 2>&1

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
    ${PUSH_PROC_DIR}/push_pushover.sh "${pushover_push_annotation}" "${SAT_NAME}" "${push_file_list}"
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

  # If any matching images are found, push images
  # handle Slack pushing if enabled
  if [ "${ENABLE_SLACK_PUSH}" == "true" ]; then
    pass_id=$($SQLITE3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
    ${PUSH_PROC_DIR}/push_slack.sh "${push_annotation} <${SLACK_LINK}?pass_id=${pass_id}>\n" $push_file_list >> $NOAA_LOG 2>&1
  fi

  # handle Twitter pushing if enabled
  if [ "${ENABLE_TWITTER_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Twitter" "INFO"
    ${PUSH_PROC_DIR}/push_twitter.sh "${push_annotation}" $push_file_list >> $NOAA_LOG 2>&1
  fi

  # handle Bluesky pushing if enabled
  if [ "${ENABLE_BLUESKY_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Bluesky" "INFO"
    python3 ${PUSH_PROC_DIR}/push_bluesky.py "${push_annotation}" ${push_file_list} >> $NOAA_LOG 2>&1
  fi

  # handle Mastodon pushing if enabled
  if [ "${ENABLE_MASTODON_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Mastodon" "INFO"
    python3 ${PUSH_PROC_DIR}/push_mastodon.py "${push_annotation}" ${push_file_list} >> $NOAA_LOG 2>&1
  fi

  # handle Facebook pushing if enabled
  if [ "${ENABLE_FACEBOOK_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Facebook" "INFO"
    python3 ${PUSH_PROC_DIR}/push_facebook.py "${push_annotation}" "${push_file_list}" >> $NOAA_LOG 2>&1
  fi

  # handle Instagram pushing if enabled
  if [ "${ENABLE_INSTAGRAM_PUSH}" == "true" ]; then
    if [[ "$daylight" -eq 1 ]]; then
      $CONVERT +append "${IMAGE_FILE_BASE}-MSA.jpg" "${IMAGE_FILE_BASE}-MSA-precip.jpg" "${IMAGE_FILE_BASE}-instagram.jpg"
    else
      $CONVERT +append "${IMAGE_FILE_BASE}-MCIR.jpg" "${IMAGE_FILE_BASE}-MCIR-precip.jpg" "${IMAGE_FILE_BASE}-instagram.jpg"
    fi
    log "Pushing image enhancements to Instagram" "INFO"
    python3 ${PUSH_PROC_DIR}/push_instagram.py "${push_annotation}" $(sed 's|/srv/images/||' <<< "${IMAGE_FILE_BASE}-instagram.jpg") ${WEB_SERVER_NAME} >> $NOAA_LOG 2>&1
    rm "${IMAGE_FILE_BASE}-instagram.jpg"
  fi

  # handle Matrix pushing if enabled
  if [ "${ENABLE_MATRIX_PUSH}" == "true" ]; then
    log "Pushing image enhancements to Matrix" "INFO"
    ${PUSH_PROC_DIR}/push_matrix.sh "${push_annotation}" $push_file_list >> $NOAA_LOG 2>&1
  fi

  if [ "${ENABLE_EMAIL_PUSH}" == "true" ]; then
    IFS=' ' read -ra image_file_array <<< "$push_file_list"
    for i in "${image_file_array[@]}"; do
      log "Emailing image enhancement $enhancement" "INFO"
      ${PUSH_PROC_DIR}/push_email.sh "${EMAIL_PUSH_ADDRESS}" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi

  if [ "${ENABLE_DISCORD_PUSH}" == "true" ]; then
    IFS=' ' read -ra image_file_array <<< "$push_file_list"
    for i in "${image_file_array[@]}"; do
      log "Pushing image enhancement $enhancement to Discord" "INFO"
      ${PUSH_PROC_DIR}/push_discord.sh "$DISCORD_NOAA_WEBHOOK" "$i" "${push_annotation}" >> $NOAA_LOG 2>&1
    done
  fi
else
    # If no matching images are found, there is no need to push images
    log "No images found - not pushing anywhere" "INFO"
fi

# calculate and report total time for capture
TIMER_END=$(date '+%s')
DIFF=$(($TIMER_END - $TIMER_START))
PROC_TIME=$(date -ud "@$DIFF" +'%H:%M.%S')
log "Total processing time: ${PROC_TIME}" "INFO"
