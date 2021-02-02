#!/bin/bash
#
# Create an "at" scheduled job for capture based on the following
# input parameter positions:
#   1. Satellite Name
#   2. Signal frequency (MHz)
#   3. Name of script to call for reception
#   4. TLE file
#
# Example:
#   ./schedule_captures.sh "NOAA 18" 137.9125 "receive_noaa.sh" "weather.tle"

### Run as a normal user
if [ $EUID -eq 0 ]; then
  echo "This script shouldn't be run as root."
  exit 1
fi

## import common lib
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# map inputs to sane var names
OBJ_NAME=$1
FREQ=$2
RECEIVE_SCRIPT=$3
TLE_FILE=$4

# come up with prediction start/end timings for pass
predict_start=$(/usr/bin/predict -t $TLE_FILE -p "${OBJ_NAME}" | head -1)
predict_end=$(/usr/bin/predict -t $TLE_FILE -p "${OBJ_NAME}" | tail -1)
max_elev=$(/usr/bin/predict -t "${TLE_FILE}" -p "${1}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')

end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
while [ "$(date --date="@${end_epoch_time}" +%D)" = "$(date +%D)" ]; do
  start_datetime=$(echo "$predict_start" | cut -d " " -f 3-4)
  start_epoch_time=$(echo "$predict_start" | cut -d " " -f 1)
  start_time_seconds=$(echo "$start_datetime" | cut -d " " -f 2 | cut -d ":" -f 3)
  timer=$(expr "${end_epoch_time}" - "${start_epoch_time}" + "${start_time_seconds}")
  file_date_ext=$(date --date="TZ=\"UTC\" ${start_datetime}" +%Y%m%d-%H%M%S)

  if [ "${max_elev}" -gt "${SAT_MIN_ELEV}" ]; then
    safe_obj_name=$(echo "${OBJ_NAME}" | sed "s/ //g")
    log "Scheduling capture for: ${safe_obj_name} ${file_date_ext} ${max_elev}" "INFO"
    echo "${NOAA_HOME}/scripts/${RECEIVE_SCRIPT} \"${OBJ_NAME}\" $FREQ ${safe_obj_name}${file_date_ext} "${TLE_FILE}" \
${start_epoch_time} ${timer} ${max_elev}" | at "$(date --date="TZ=\"UTC\" ${start_datetime}" +"%H:%M %D")"
    sqlite3 $DB_FILE "insert or replace into predict_passes (sat_name,pass_start,pass_end,max_elev,is_active) values (\"$safe_obj_name\",$start_epoch_time,$end_epoch_time,$max_elev,1);"
  fi
  next_predict=$(expr "${end_epoch_time}" + 60)
  predict_start=$(/usr/bin/predict -t "${TLE_FILE}" -p "${OBJ_NAME}" "${next_predict}" | head -1)
  predict_end=$(/usr/bin/predict -t "${TLE_FILE}" -p "${OBJ_NAME}"  "${next_predict}" | tail -1)
  max_elev=$(/usr/bin/predict -t "${TLE_FILE}" -p "${OBJ_NAME}" "${next_predict}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
  end_epoch_time=$(echo "${predict_end}" | cut -d " " -f 1)
done
