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
capture_start=$START_DATE

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
AUDIO_FILE_BASE="${NOAA_AUDIO_OUTPUT}/${FILENAME_BASE}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME_BASE}"
IMAGE_THUMB_BASE="${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}"

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
     "hackrf") 
         samplerate="4e6" 
         receiver="hackrf" 
         ;; 
     "sdrplay") 
         samplerate="2e6" 
         receiver="sdrplay" 
         ;; 
     *) 
         echo "Invalid RECEIVER_TYPE value: $RECEIVER_TYPE" 
         exit 1 
         ;; 
 esac

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
export SUN_ELEV=$(python3 "$SCRIPTS_DIR"/tools/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an existing rtl_fm instance running, I quit" "ERROR"
  exit 1
elif pgrep -f ${RECEIVER_TYPE}_noaa_apt_rx.py > /dev/null; then
  log "There is an existing gnuradio noaa capture instance running, I quit" "ERROR"
  exit 1
elif pgrep -f ${RECEIVER_TYPE}_m2_lrpt_rx.py > /dev/null; then
  log "There is an existing gnuradio M2 capture instance running, I quit" "ERROR"
  exit 1
fi

#start capture
if [ "$NOAA_RECEIVER" == "rtl_fm" ]; then
  log "Starting rtl_fm record" "INFO"
  ${AUDIO_PROC_DIR}/noaa_record_rtl_fm.sh "${SAT_NAME}" $CAPTURE_TIME "${AUDIO_FILE_BASE}.wav" >> $NOAA_LOG 2>&1
elif [ "$NOAA_RECEIVER" == "gnuradio" ]; then
  log "Starting gnuradio record" "INFO"
  ${AUDIO_PROC_DIR}/noaa_record_gnuradio.sh "${SAT_NAME}" $CAPTURE_TIME "${AUDIO_FILE_BASE}.wav" >> $NOAA_LOG 2>&1
elif [ "$NOAA_RECEIVER" == "satdump" ]; then
  log "Starting SatDump recording and live decoding" "INFO"
  satdump live noaa_apt . --source $receiver --samplerate $samplerate --frequency "${NOAA_FREQUENCY}e6" --satellite_number ${SAT_NUMBER} --general_gain $GAIN --timeout $CAPTURE_TIME --finish_processing >> $NOAA_LOG 2>&1
  rm satdump.logs product.cbor dataset.json
fi

# wait for files to close
sleep 2

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------

polar_az_el=0
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
                                  "azel" >> $NOAA_LOG 2>&1
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-azel.jpg" "${IMAGE_THUMB_BASE}-polar-azel.jpg" >> $NOAA_LOG 2>&1
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
                                  "direction" >> $NOAA_LOG 2>&1
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-polar-direction.png" "${IMAGE_THUMB_BASE}-polar-direction.png" >> $NOAA_LOG 2>&1
fi

if [ -f "${AUDIO_FILE_BASE}.wav" ]; then
  #generate outputs
  spectrogram=0
  if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
    log "Producing spectrogram" "INFO"
    spectrogram=1
    spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
    ${IMAGE_PROC_DIR}/spectrogram.sh "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" "${spectro_text}" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png" >> $NOAA_LOG 2>&1
  fi

  pristine=0
  if [[ "${PRODUCE_NOAA_PRISTINE}" == "true" ]]; then
    log "Producing pristine image" "INFO"
    pristine=1
    ${IMAGE_PROC_DIR}/noaa_pristine.sh "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-pristine.jpg" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-pristine.jpg" "${IMAGE_THUMB_BASE}-pristine.jpg" >> $NOAA_LOG 2>&1
  fi

  histogram=0
  if [ "${PRODUCE_NOAA_PRISTINE_HISTOGRAM}" == "true" ]; then
    tmp_dir="${NOAA_HOME}/tmp"
    histogram=1
    histogram_text="${capture_start} @ ${SAT_MAX_ELEVATION}° Gain: ${GAIN}"

    log "Generating Data for Histogram" "INFO"
    ${IMAGE_PROC_DIR}/noaa_histogram_data.sh "${AUDIO_FILE_BASE}.wav" "${tmp_dir}/${FILENAME_BASE}-a.png" "${tmp_dir}/${FILENAME_BASE}-b.png" >> $NOAA_LOG 2>&1

    log "Producing histogram of NOAA pristine image channel A" "INFO"
    ${IMAGE_PROC_DIR}/histogram.sh "${tmp_dir}/${FILENAME_BASE}-a.png" "${IMAGE_FILE_BASE}-histogram-a.jpg" "${SAT_NAME} - Channel A" "${histogram_text}" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-histogram-a.jpg" "${IMAGE_THUMB_BASE}-histogram-a.jpg" >> $NOAA_LOG 2>&1

    log "Producing histogram of NOAA pristine image channel B" "INFO"
    ${IMAGE_PROC_DIR}/histogram.sh "${tmp_dir}/${FILENAME_BASE}-b.png" "${IMAGE_FILE_BASE}-histogram-b.jpg" "${SAT_NAME} - Channel B" "${histogram_text}" >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-histogram-b.jpg" "${IMAGE_THUMB_BASE}-histogram-b.jpg" >> $NOAA_LOG 2>&1

    log "Horizontally Merge two Histogram Channels to single image for output"
    $CONVERT +append "${IMAGE_FILE_BASE}-histogram-a.jpg" "${IMAGE_FILE_BASE}-histogram-b.jpg" -resize x500 "${IMAGE_FILE_BASE}-histogram.jpg" >>$NOAA_LOG 2>&1
    $CONVERT +append "${IMAGE_THUMB_BASE}-histogram-a.jpg" "${IMAGE_THUMB_BASE}-histogram-b.jpg" -resize x300 "${IMAGE_THUMB_BASE}-histogram.jpg" >>$NOAA_LOG 2>&1

    rm "${IMAGE_FILE_BASE}-histogram-a.jpg" "${IMAGE_FILE_BASE}-histogram-b.jpg" "${IMAGE_THUMB_BASE}-histogram-a.jpg" "${IMAGE_THUMB_BASE}-histogram-b.jpg" "${tmp_dir}/${FILENAME_BASE}-a.png" "${tmp_dir}/${FILENAME_BASE}-b.png"
  fi

  log "Bulding pass map" "INFO"
  # add 10 seconds to ensure we account for small deviations in timing - being even a second too soon
  # can cause an error of "wxmap: warning: could not find matching pass to build overlay map.", while
  # going over the start time by a few seconds while still being within the pass timing causes wxmap
  # to track *back* to the start of the pass
  epoch_adjusted=$(($PASS_START + 10))

  # calculate any extra map options such as crosshair for base station, coloring, etc.
  extra_map_opts=""
  if [ "${NOAA_MAP_CROSSHAIR_ENABLE}" == "true" ]; then
    extra_map_opts="${extra_map_opts} -l 1 -c l:${NOAA_MAP_CROSSHAIR_COLOR}"
  else
    extra_map_opts="${extra_map_opts} -l 0"
  fi
  if [ "${NOAA_MAP_GRID_DEGREES}" != "0.0" ]; then
    extra_map_opts="${extra_map_opts} -g ${NOAA_MAP_GRID_DEGREES} -c g:${NOAA_MAP_GRID_COLOR}"
  else
    extra_map_opts="${extra_map_opts} -g 0.0"
  fi
  if [ "${NOAA_MAP_COUNTRY_BORDER_ENABLE}" == "true" ]; then
    extra_map_opts="${extra_map_opts} -C 1 -c C:${NOAA_MAP_COUNTRY_BORDER_COLOR}"
  else
    extra_map_opts="${extra_map_opts} -C 0"
  fi
  if [ "${NOAA_MAP_STATE_BORDER_ENABLE}" == "true" ]; then
    extra_map_opts="${extra_map_opts} -S 1 -c S:${NOAA_MAP_STATE_BORDER_COLOR}"
  else
    extra_map_opts="${extra_map_opts} -S 0"
  fi

  # build overlay map
  map_overlay="${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"
  $WXMAP -T "${SAT_NAME}" -H "${TLE_FILE}" -p 0 ${extra_map_opts} -o "${epoch_adjusted}" $map_overlay >> $NOAA_LOG 2>&1

  # run all enhancements all the time - any that cannot be produced will
  # simply be left out/not included, so there is no harm in running all of them
  if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
    ENHANCEMENTS="${NOAA_DAY_ENHANCEMENTS}"
    daylight=1
  else
    ENHANCEMENTS="${NOAA_NIGHT_ENHANCEMENTS}"
    daylight=0
  fi

  # build images based on enhancements defined
  has_one_image=0
  push_file_list=""
  for enhancement in $ENHANCEMENTS; do
    export ENHANCEMENT=$enhancement
    log "Decoding image" "INFO"

    if [$enhancement == "avi"]; then
      ${IMAGE_PROC_DIR}/noaa_avi.sh $map_overlay "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-$enhancement.jpg" $enhancement >> $NOAA_LOG 2>&1
    else
      ${IMAGE_PROC_DIR}/noaa_enhancements.sh $map_overlay "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-$enhancement.jpg" $enhancement >> $NOAA_LOG 2>&1
    fi

    if [ -f "${IMAGE_FILE_BASE}-$enhancement.jpg" ]; then
      filesize=$(wc -c "${IMAGE_FILE_BASE}-$enhancement.jpg" | awk '{print $1}')
      ${IMAGE_PROC_DIR}/noaa_normalize_annotate.sh "${IMAGE_FILE_BASE}-$enhancement.jpg" "${IMAGE_FILE_BASE}-$enhancement.jpg" $NOAA_IMAGE_QUALITY >> $NOAA_LOG 2>&1
      ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-$enhancement.jpg" "${IMAGE_THUMB_BASE}-$enhancement.jpg" >> $NOAA_LOG 2>&1
      # check that the file actually has content
      if [ $filesize -gt 20480 ]; then
        # at least one good image
        has_one_image=1

        # capture list of files to push to Twitter
        push_file_list="${push_file_list} ${IMAGE_FILE_BASE}-$enhancement.jpg"

        # determine if auto-gain is set - handles "0" and "0.0" floats
        gain=$GAIN
        if [ $(echo "$GAIN==0"|bc) -eq 1 ]; then
          gain='Automatic'
        fi

        # create push annotation string (annotation in the email subject, discord text, etc.)
        # note this is NOT the annotation on the image, which is driven by the config/annotation/annotation.html.j2 file
        push_annotation=""
        if [ "${GROUND_STATION_LOCATION}" != "" ]; then
          push_annotation="Ground Station: ${GROUND_STATION_LOCATION}\n"
        fi
        push_annotation="${push_annotation}${SAT_NAME} ${enhancement} ${capture_start}"
        push_annotation="${push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
        push_annotation="${push_annotation} Sun Elevation: ${SUN_ELEV}°"
        push_annotation="${push_annotation} Gain: ${gain}"
        push_annotation="${push_annotation} | ${PASS_DIRECTION}"

        if [ "${ENABLE_EMAIL_PUSH}" == "true" ]; then
          log "Emailing image enhancement $enhancement" "INFO"
          ${PUSH_PROC_DIR}/push_email.sh "${EMAIL_PUSH_ADDRESS}" "${IMAGE_FILE_BASE}-$enhancement.jpg" "${push_annotation}" >> $NOAA_LOG 2>&1
        fi

        if [ "${ENABLE_DISCORD_PUSH}" == "true" ]; then
          log "Pushing image enhancement $enhancement to Discord" "INFO"
          ${PUSH_PROC_DIR}/push_discord.sh "${IMAGE_FILE_BASE}-$enhancement.jpg" "${push_annotation}" >> $NOAA_LOG 2>&1
        fi
      else
        log "No image with enhancement $enhancement created - not pushing anywhere" "INFO"
        rm "${IMAGE_FILE_BASE}-$enhancement.jpg"
      fi
    fi
  done

  rm $map_overlay

  if [ "$DELETE_AUDIO" = true ]; then
    log "Deleting audio files" "INFO"
    rm "${AUDIO_FILE_BASE}.wav"
  fi
else
  for i in *.png; do
    ${IMAGE_PROC_DIR}/noaa_normalize_annotate.sh "$i" "${IMAGE_FILE_BASE}${i%.png}.jpg" $NOAA_IMAGE_QUALITY >> $NOAA_LOG 2>&1
    ${IMAGE_PROC_DIR}/thumbnail.sh 300 "$i" "${IMAGE_THUMB_BASE}${i%.png}.jpg" >> $NOAA_LOG 2>&1
    push_file_list="${push_file_list} ${IMAGE_FILE_BASE}${i%.png}.jpg"
    rm $i
  done
fi

if [ -n "$(find /srv/images -maxdepth 1 -type f -name "$(basename "$IMAGE_FILE_BASE")*.jpg" -print -quit)" ]; then
    # If any matching images are found, push images
      # handle Slack pushing if enabled
  if [ "${ENABLE_SLACK_PUSH}" == "true" ]; then
    slack_push_annotation=""
    if [ "${GROUND_STATION_LOCATION}" != "" ]; then
      slack_push_annotation="Ground Station: ${GROUND_STATION_LOCATION}\n "
    fi
    slack_push_annotation="${slack_push_annotation}${SAT_NAME} ${capture_start}\n"
    slack_push_annotation="${slack_push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}\n"
    slack_push_annotation="${slack_push_annotation} Sun Elevation: ${SUN_ELEV}°\n"
    slack_push_annotation="${slack_push_annotation} Gain: ${gain} | ${PASS_DIRECTION}\n"

    pass_id=$($SQLITE3 $DB_FILE "SELECT id FROM decoded_passes ORDER BY id DESC LIMIT 1;")
    slack_push_annotation="${slack_push_annotation} <${SLACK_LINK_URL}?pass_id=${pass_id}>\n";

    ${PUSH_PROC_DIR}/push_slack.sh "${slack_push_annotation}" $push_file_list
  fi

  # handle twitter pushing if enabled
  if [ "${ENABLE_TWITTER_PUSH}" == "true" ]; then
    # create push annotation specific to twitter
    # note this is NOT the annotation on the image, which is driven by the config/annotation/annotation.html.j2 file
    twitter_push_annotation=""
    if [ "${GROUND_STATION_LOCATION}" != "" ]; then
      twitter_push_annotation="Ground Station: ${GROUND_STATION_LOCATION} "
    fi
    twitter_push_annotation="${twitter_push_annotation}${SAT_NAME} ${capture_start}"
    twitter_push_annotation="${twitter_push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
    twitter_push_annotation="${twitter_push_annotation} Sun Elevation: ${SUN_ELEV}°"
    twitter_push_annotation="${twitter_push_annotation} Gain: ${gain}"
    twitter_push_annotation="${twitter_push_annotation} | ${PASS_DIRECTION}"

    log "Pushing image enhancements to Twitter" "INFO"
    ${PUSH_PROC_DIR}/push_twitter.sh "${twitter_push_annotation}" $push_file_list
  fi

  # handle facebook pushing if enabled
  if [ "${ENABLE_FACEBOOK_PUSH}" == "true" ]; then
    facebook_push_annotation=""
    if [ "${GROUND_STATION_LOCATION}" != "" ]; then
      facebook_push_annotation="Ground Station: ${GROUND_STATION_LOCATION} "
    fi
    facebook_push_annotation="${facebook_push_annotation}${SAT_NAME} ${capture_start}"
    facebook_push_annotation="${facebook_push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
    facebook_push_annotation="${facebook_push_annotation} Sun Elevation: ${SUN_ELEV}°"
    facebook_push_annotation="${facebook_push_annotation} Gain: ${gain}"
    facebook_push_annotation="${facebook_push_annotation} | ${PASS_DIRECTION}"

    log "Pushing image enhancements to Facebook" "INFO"
    ${PUSH_PROC_DIR}/push_facebook.py "${facebook_push_annotation}" "${push_file_list}"
  fi

  # handle instagram pushing if enabled
  if [ "${ENABLE_INSTAGRAM_PUSH}" == "true" ]; then
    instagram_push_annotation=""
    if [ "${GROUND_STATION_LOCATION}" != "" ]; then
      instagram_push_annotation="Ground Station: ${GROUND_STATION_LOCATION} "
    fi
    instagram_push_annotation="${instagram_push_annotation}${SAT_NAME} ${capture_start}"
    instagram_push_annotation="${instagram_push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
    instagram_push_annotation="${instagram_push_annotation} Sun Elevation: ${SUN_ELEV}°"
    instagram_push_annotation="${instagram_push_annotation} Gain: ${gain}"
    instagram_push_annotation="${instagram_push_annotation} | ${PASS_DIRECTION}"

    if [[ "$daylight" -eq 1 ]]; then
      $CONVERT +append "${IMAGE_FILE_BASE}-MSA.jpg" "${IMAGE_FILE_BASE}-MSA-precip.jpg" "${IMAGE_FILE_BASE}-instagram.jpg"
    else
      $CONVERT +append "${IMAGE_FILE_BASE}-MCIR.jpg" "${IMAGE_FILE_BASE}-MCIR-precip.jpg" "${IMAGE_FILE_BASE}-instagram.jpg"
    fi

    log "Pushing image enhancements to Instagram" "INFO"
    ${PUSH_PROC_DIR}/push_instagram.py "${instagram_push_annotation}" $(sed 's|/srv/images/||' <<< "${IMAGE_FILE_BASE}-instagram.jpg") ${WEB_SERVER_NAME}
    rm "${IMAGE_FILE_BASE}-instagram.jpg"
  fi
  # handle matrix pushing if enabled
  if [ "${ENABLE_MATRIX_PUSH}" == "true" ]; then
      # create push annotation specific to matrix
      # note this is NOT the annotation on the image, which is driven by the config/annotation/annotation.html.j2 file
      matrix_push_annotation=""
      if [ "${GROUND_STATION_LOCATION}" != "" ]; then
          matrix_push_annotation="Ground Station: ${GROUND_STATION_LOCATION} "
      fi
      matrix_push_annotation="${matrix_push_annotation}${SAT_NAME} ${capture_start}"
      matrix_push_annotation="${matrix_push_annotation} Max Elev: ${SAT_MAX_ELEVATION}° ${PASS_SIDE}"
      matrix_push_annotation="${matrix_push_annotation} Sun Elevation: ${SUN_ELEV}°"
      matrix_push_annotation="${matrix_push_annotation} Gain: ${gain}"
      matrix_push_annotation="${matrix_push_annotation} | ${PASS_DIRECTION}"

      log "Pushing image enhancements to Matrix" "INFO"
      ${PUSH_PROC_DIR}/push_matrix.sh "${matrix_push_annotation}" $push_file_list
  fi
else
    # If no matching images are found, there is no need to push images
    log "No images found - not pushing anywhere" "INFO"
fi

$SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (id, pass_start, file_path, daylight_pass, sat_type, has_spectrogram, has_pristine, has_polar_az_el, has_polar_direction, has_histogram, gain) \
                                    VALUES ( \
                                      (SELECT id FROM decoded_passes WHERE pass_start = $EPOCH_START), \
                                      $EPOCH_START, \"$FILENAME_BASE\", $daylight, 1, $spectrogram, $pristine, $polar_az_el, $polar_direction, $histogram, $GAIN \
                                    );"

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
                  );"

# calculate and report total time for capture
TIMER_END=$(date '+%s')
DIFF=$(($TIMER_END - $TIMER_START))
PROC_TIME=$(date -ud "@$DIFF" +'%H:%M.%S')
log "Total processing time: ${PROC_TIME}" "INFO"
