#!/bin/bash
#
# Purpose: Create an "at" scheduled job for capture based on the following
#          input parameter positions:
#            1. Satellite Name
#            2. Name of script to call for reception
#            3. TLE file
#            4. Start time to predict passes (ms)
#            5. End time to predict passes (ms)
#
# Example:
#   ./schedule_captures.sh "NOAA 18" "receive_noaa.sh" "weather.tle" 1617422399 1617425300

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# map inputs to sane var names
OBJ_NAME=$1
RECEIVE_SCRIPT=$2
TLE_FILE=$3
START_TIME_MS=$4
END_TIME_MS=$5

if [ "$OBJ_NAME" == "NOAA 15" ]; then
  SAT_MIN_ELEV=$NOAA_15_SAT_MIN_ELEV
fi
if [ "$OBJ_NAME" == "NOAA 18" ]; then
  SAT_MIN_ELEV=$NOAA_18_SAT_MIN_ELEV
fi
if [ "$OBJ_NAME" == "NOAA 19" ]; then
  SAT_MIN_ELEV=$NOAA_19_SAT_MIN_ELEV
fi
if [ "$OBJ_NAME" == "METEOR-M 2" ]; then
  SAT_MIN_ELEV=$METEOR_M2_3_SAT_MIN_ELEV
fi
if [ "$OBJ_NAME" == "METEOR-M2 3" ]; then
  SAT_MIN_ELEV=$METEOR_M2_3_SAT_MIN_ELEV
fi

# come up with prediction start/end timings for pass
predict_start=$($PREDICT -t $TLE_FILE -p "${OBJ_NAME}" "${START_TIME_MS}" | head -1)
predict_end=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" "${START_TIME_MS}" | tail -1)
max_elev=$($PREDICT      -t $TLE_FILE -p "${OBJ_NAME}" "${START_TIME_MS}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
azimuth_at_max=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" "${START_TIME_MS}" | awk -v max=0 -v az=0 '{if($5>max){max=$5;az=$6}}END{print az}')
end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
starting_azimuth=$(echo "${predict_start}" | awk '{print $6}')

# get and schedule passes for user-defined days
while [ "$(date --date="@${end_epoch_time}" +"%s")" -le "${END_TIME_MS}" ]; do
  start_datetime=$(echo "$predict_start" | cut -d " " -f 3-4)
  start_epoch_time=$(echo "$predict_start" | cut -d " " -f 1)
  start_time_seconds=$(echo "$start_datetime" | cut -d " " -f 2 | cut -d ":" -f 3)
  timer=$(expr "${end_epoch_time}" - "${start_epoch_time}" + "${start_time_seconds}")
  file_date_ext=$(date --date="TZ=\"UTC\" ${start_datetime}" +%Y%m%d-%H%M%S)

  schedule_enabled_by_sun_elev=1
  if [ "$OBJ_NAME" == "METEOR-M2 3" ]; then
      START_SUN_ELEV=$(python3 "$SCRIPTS_DIR"/tools/sun.py "$start_epoch_time")
      if [ "${START_SUN_ELEV}" -lt "${METEOR_M2_3_SCHEDULE_SUN_MIN_ELEV}" ]; then
        log "Not scheduling Meteor-M2 3 with START TIME $start_epoch_time because $START_SUN_ELEV is below configured minimum sun elevation $METEOR_M2_3_SCHEDULE_SUN_MIN_ELEV" "INFO"
        schedule_enabled_by_sun_elev=0
      fi
  fi

  # schedule capture if elevation is above configured minimum
  if [ "${max_elev}" -gt "${SAT_MIN_ELEV}" ] && [ "${schedule_enabled_by_sun_elev}" -eq "1" ]; then
    direction="null"

    # calculate travel direction
    if [ $starting_azimuth -le 90 ] || [ $starting_azimuth -ge 270 ]; then
      direction="Southbound"
    else
      direction="Northbound"
    fi

    # calculate side of travel
    pass_side="W"
    if [ $azimuth_at_max -ge 0 ] && [ $azimuth_at_max -le 180 ]; then
      pass_side="E"
    fi

    # should at send mail ?
    mail_arg=""
    if [ "${DISABLE_AT_MAIL}" == "true" ]; then
      mail_arg="-M"
    fi

    printf -v safe_obj_name "%q" $(echo "${OBJ_NAME}" | sed "s/ /-/g")
    log "Scheduling capture for: ${safe_obj_name} ${file_date_ext} ${max_elev}" "INFO"
    job_output=$(echo "${NOAA_HOME}/scripts/${RECEIVE_SCRIPT} \"${OBJ_NAME}\" ${safe_obj_name}-${file_date_ext} ${TLE_FILE} \
                                                              ${start_epoch_time} ${timer} ${max_elev} ${direction} ${pass_side}" \
                | at "$(date --date="TZ=\"UTC\" ${start_datetime}" +"%H:%M %D")" ${mail_arg} 2>&1)

    # attempt to capture the job id if job scheduling succeeded
    at_job_id=$(echo $job_output | sed -n 's/.*job \([0-9]\+\) at.*/\1/p')
    if [ -z "${at_job_id}" ]; then
      log "Issue scheduling job: ${job_output}" "WARN"
    else
      log "Scheduled capture with job id: ${at_job_id}" "INFO"

      # update database with scheduled pass
      $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO predict_passes (sat_name,pass_start,pass_end,max_elev,is_active,pass_start_azimuth,azimuth_at_max,direction,at_job_id) VALUES (\"${OBJ_NAME}\",$start_epoch_time,$end_epoch_time,$max_elev,1,$starting_azimuth,$azimuth_at_max,'$direction',$at_job_id);"
    fi
  fi

  next_predict=$(expr "${end_epoch_time}" + 60)
  predict_start=$($PREDICT -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | head -1)
  predict_end=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | tail -1)
  max_elev=$($PREDICT      -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
  azimuth_at_max=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | awk -v max=0 -v az=0 '{if($5>max){max=$5;az=$6}}END{print az}')
  end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
  starting_azimuth=$(echo "${predict_start}" | awk '{print $6}')
done
