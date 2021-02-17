#!/bin/bash
#
# Purpose: High-level scheduling script - schedules all desired satellite
#          and orbital captures.

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# some constants
WEATHER_TXT="${NOAA_HOME}/tmp/weather.txt"
AMATEUR_TXT="${NOAA_HOME}/tmp/amateur.txt"
TLE_OUTPUT="${NOAA_HOME}/tmp/orbit.tle"

# get the txt files for orbit information
wget -qr http://www.celestrak.com/NORAD/elements/weather.txt -O "${WEATHER_TXT}" >> $NOAA_LOG 2>&1
wget -qr http://www.celestrak.com/NORAD/elements/amateur.txt -O "${AMATEUR_TXT}" >> $NOAA_LOG 2>&1

# create tle files for scheduling
#   note: it's really unfortunate but a directory structure any deeper than 'tmp' in the
#   below results in a buffer overflow reported by the predict application, presumably
#   because it cannot handle that level of sub-directory
log "Clearing and re-creating TLE file with latest..." "INFO"
echo -n "" > $TLE_OUTPUT
grep "NOAA 15" $WEATHER_TXT -A 2 >> $TLE_OUTPUT
grep "NOAA 18" $WEATHER_TXT -A 2 >> $TLE_OUTPUT
grep "NOAA 19" $WEATHER_TXT -A 2 >> $TLE_OUTPUT
grep "METEOR-M 2" $WEATHER_TXT -A 2 >> $TLE_OUTPUT

# remove 'at' jobs to make way for new jobs
log "Clearing existing scheduled 'at' capture jobs..." "INFO"
for i in $(atq | awk '{print $1}'); do
  atrm "$i"
done

# create schedules to call respective receive scripts
log "Scheduling new capture jobs..." "INFO"
if [ "$SCHEDULE_NOAA" == "true" ]; then
  $NOAA_HOME/scripts/schedule_captures.sh "NOAA 15" "receive_noaa.sh" $TLE_OUTPUT >> $NOAA_LOG 2>&1
  $NOAA_HOME/scripts/schedule_captures.sh "NOAA 18" "receive_noaa.sh" $TLE_OUTPUT >> $NOAA_LOG 2>&1
  $NOAA_HOME/scripts/schedule_captures.sh "NOAA 19" "receive_noaa.sh" $TLE_OUTPUT >> $NOAA_LOG 2>&1
fi

if [ "$SCHEDULE_METEOR" == "true" ]; then
  $NOAA_HOME/scripts/schedule_captures.sh "METEOR-M 2" "receive_meteor.sh" $TLE_OUTPUT >> $NOAA_LOG 2>&1
fi
log "Done scheduling jobs!" "INFO"

if [ "${ENABLE_EMAIL_SCHEDULE_PUSH}" == "true" ]; then
  # create annotation to send as subject for email
  annotation="Scheduled Passes | "
  if [ "${GROUND_STATION_LOCATION}" != "" ]; then
    annotation="${annotation}Ground Station: ${GROUND_STATION_LOCATION} | "
  fi
  annotation="${annotation}Timezone Offset: ${TZ_OFFSET}"

  log "Generating image of pass list schedule for email" "INFO"
  pass_image="${NOAA_HOME}/tmp/pass-list.jpg"
  $WKHTMLTOIMG --format jpg --quality 100 "http://localhost:${WEBPANEL_PORT}/" "${pass_image}" >> $NOAA_LOG 2>&1

  # crop the header (and optionally, satvis iframe, if enabled) out of pass list
  log "Removing header from pass list image" "INFO"
  $CONVERT "${pass_image}" -gravity North -chop 0x190 "${pass_image}" >> $NOAA_LOG 2>&1

  if [ "${ENABLE_SATVIS}" == "true" ]; then
    log "Removing Satvis iFrame from pass list image" "INFO"
    $CONVERT "${pass_image}" -gravity North -chop 0x510 "${pass_image}" >> $NOAA_LOG 2>&1
  fi

  log "Emailing pass list schedule to destination address" "INFO"
  ${PUSH_PROC_DIR}/push_email.sh "${EMAIL_PUSH_ADDRESS}" "${pass_image}" "${annotation}"
fi
