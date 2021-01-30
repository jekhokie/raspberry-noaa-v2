#!/bin/bash

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

wget -qr http://www.celestrak.com/NORAD/elements/weather.txt -O "${NOAA_HOME}"/tmp/weather.txt
wget -qr http://www.celestrak.com/NORAD/elements/amateur.txt -O "${NOAA_HOME}"/tmp/amateur.txt

# it's really unfortunate but a directory structure any deeper than 'tmp' in the below
# results in a buffer overflow reported by the predict application, presumably because
# it cannot handle that level of sub-directory
grep "NOAA 15" "${NOAA_HOME}"/tmp/weather.txt -A 2 > "${NOAA_HOME}"/tmp/weather.tle
grep "NOAA 18" "${NOAA_HOME}"/tmp/weather.txt -A 2 >> "${NOAA_HOME}"/tmp/weather.tle
grep "NOAA 19" "${NOAA_HOME}"/tmp/weather.txt -A 2 >> "${NOAA_HOME}"/tmp/weather.tle
grep "METEOR-M 2" "${NOAA_HOME}"/tmp/weather.txt -A 2 >> "${NOAA_HOME}"/tmp/weather.tle
if [ "$SCHEDULE_ISS" == "true" ]; then
    grep "ZARYA" "${NOAA_HOME}"/tmp/amateur.txt -A 2 > "${NOAA_HOME}"/tmp/amateur.tle
fi

#Remove all AT jobs
for i in $(atq | awk '{print $1}'); do
  atrm "$i"
done

#Schedule Satellite Passes:
if [ "$SCHEDULE_ISS" == "true" ]; then
    "${NOAA_HOME}"/scripts/schedule_iss.sh "ISS (ZARYA)" 145.8000
fi
"${NOAA_HOME}"/scripts/schedule_meteor.sh "METEOR-M 2" 137.1000
"${NOAA_HOME}"/scripts/schedule_sat.sh "NOAA 19" 137.1000
"${NOAA_HOME}"/scripts/schedule_sat.sh "NOAA 18" 137.9125
"${NOAA_HOME}"/scripts/schedule_sat.sh "NOAA 15" 137.6200
