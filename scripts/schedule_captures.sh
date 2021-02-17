#!/bin/bash
#
# Purpose: Create an "at" scheduled job for capture based on the following
#          input parameter positions:
#            1. Satellite Name
#            2. Name of script to call for reception
#            3. TLE file
#
# Example:
#   ./schedule_captures.sh "NOAA 18" "receive_noaa.sh" "weather.tle"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# map inputs to sane var names
OBJ_NAME=$1
RECEIVE_SCRIPT=$2
TLE_FILE=$3

# come up with prediction start/end timings for pass
predict_start=$($PREDICT -t $TLE_FILE -p "${OBJ_NAME}" | head -1)
predict_end=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" | tail -1)
max_elev=$($PREDICT      -t $TLE_FILE -p "${OBJ_NAME}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
starting_azimuth=$(echo "${predict_start}" | awk '{print $6}')

# TLE file isn't needed for running meteor captures
receiver_tle_file=$TLE_FILE
if [ "${OBJ_NAME}" = "METEOR-M 2" ]; then
  receiver_tle_file=""
fi

while [ "$(date --date="@${end_epoch_time}" +%D)" = "$(date +%D)" ]; do
  start_datetime=$(echo "$predict_start" | cut -d " " -f 3-4)
  start_epoch_time=$(echo "$predict_start" | cut -d " " -f 1)
  start_time_seconds=$(echo "$start_datetime" | cut -d " " -f 2 | cut -d ":" -f 3)
  timer=$(expr "${end_epoch_time}" - "${start_epoch_time}" + "${start_time_seconds}")
  file_date_ext=$(date --date="TZ=\"UTC\" ${start_datetime}" +%Y%m%d-%H%M%S)

  # schedule capture if elevation is above configured minimum
  if [ "${max_elev}" -gt "${SAT_MIN_ELEV}" ]; then
    direction="null"

    # calculate travel direction
    if [ $starting_azimuth -le 90 ] || [ $starting_azimuth -ge 270 ]; then
      direction="Southbound"
    else
      direction="Northbound"
    fi

    printf -v safe_obj_name "%q" $(echo "${OBJ_NAME}" | sed "s/ /-/g")
    log "Scheduling capture for: ${safe_obj_name} ${file_date_ext} ${max_elev}" "INFO"
    echo "${NOAA_HOME}/scripts/${RECEIVE_SCRIPT} \"${OBJ_NAME}\" ${safe_obj_name}-${file_date_ext} "${receiver_tle_file}" \
${start_epoch_time} ${timer} ${max_elev}" | at "$(date --date="TZ=\"UTC\" ${start_datetime}" +"%H:%M %D")"

    # update database with scheduled pass
    $SQLITE3 $DB_FILE "insert or replace into predict_passes (sat_name,pass_start,pass_end,max_elev,is_active,pass_start_azimuth,direction) values (\"${OBJ_NAME}\",$start_epoch_time,$end_epoch_time,$max_elev,1,$starting_azimuth,'$direction');"
  fi

  next_predict=$(expr "${end_epoch_time}" + 60)
  predict_start=$($PREDICT -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | head -1)
  predict_end=$($PREDICT   -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | tail -1)
  max_elev=$($PREDICT      -t $TLE_FILE -p "${OBJ_NAME}" "${next_predict}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
  end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
  starting_azimuth=$(echo "${predict_start}" | awk '{print $6}')
done
