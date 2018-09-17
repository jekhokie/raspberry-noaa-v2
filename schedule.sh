#!/bin/sh

## debug
#set -x

. ~/.noaa.conf

wget -qr https://www.celestrak.com/NORAD/elements/weather.txt -O "${NOAA_HOME}"/predict/weather.txt
grep "NOAA 15" "${NOAA_HOME}"/predict/weather.txt -A 2 > "${NOAA_HOME}"/predict/weather.tle
grep "NOAA 18" "${NOAA_HOME}"/predict/weather.txt -A 2 >> "${NOAA_HOME}"/predict/weather.tle
grep "NOAA 19" "${NOAA_HOME}"/predict/weather.txt -A 2 >> "${NOAA_HOME}"/predict/weather.tle

#Remove all AT jobs
for i in $(atq | awk '{print $1}');do atrm "$i";done

#Schedule Satellite Passes:
"${NOAA_HOME}"/schedule_sat.sh "NOAA 19" 137.1000
"${NOAA_HOME}"/schedule_sat.sh "NOAA 18" 137.9125
"${NOAA_HOME}"/schedule_sat.sh "NOAA 15" 137.6200
