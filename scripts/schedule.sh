#!/bin/bash
#
# High-level scheduling script - schedules all desired satellite and orbital captures.

# run as a non-root user
if [ $EUID -eq 0 ]; then
  echo "This script shouldn't be run as root."
  exit 1
fi

# import common lib
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# some constants
WEATHER_TXT="${NOAA_HOME}/tmp/weather.txt"
AMATEUR_TXT="${NOAA_HOME}/tmp/amateur.txt"
TLE_OUTPUT="${NOAA_HOME}/tmp/orbit.tle"

# get the txt files for orbit information
wget -qr http://www.celestrak.com/NORAD/elements/weather.txt -O "${WEATHER_TXT}"
wget -qr http://www.celestrak.com/NORAD/elements/amateur.txt -O "${AMATEUR_TXT}"

# create tle files for scheduling
#   note: it's really unfortunate but a directory structure any deeper than 'tmp' in the
#   below results in a buffer overflow reported by the predict application, presumably
#   because it cannot handle that level of sub-directory
log "Clearing and re-creating TLE file with latest..." "INFO"
echo -n "" > $TLE_OUTPUT
if [ "$SCHEDULE_ISS" == "true" ]; then
    grep "ZARYA" $AMATEUR_TXT -A 2 >> $TLE_OUTPUT
fi
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
if [ "$SCHEDULE_ISS" == "true" ]; then
  $NOAA_HOME/scripts/schedule_captures.sh "ISS (ZARYA)" 145.8000 "receive_iss.sh" $TLE_OUTPUT
fi
$NOAA_HOME/scripts/schedule_captures.sh "NOAA 15" 137.6200 "receive_noaa.sh" $TLE_OUTPUT
$NOAA_HOME/scripts/schedule_captures.sh "NOAA 18" 137.9125 "receive_noaa.sh" $TLE_OUTPUT
$NOAA_HOME/scripts/schedule_captures.sh "NOAA 19" 137.1000 "receive_noaa.sh" $TLE_OUTPUT
$NOAA_HOME/scripts/schedule_captures.sh "METEOR-M 2" 137.1000 "receive_meteor.sh" $TLE_OUTPUT
