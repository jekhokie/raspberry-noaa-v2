#!/bin/bash

## debug
# set -x

## import common lib
. "$HOME/.noaa.conf"
. "$NOAA_HOME/common.sh"

SAT_MIN_ELEV=10

PREDICTION_START=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}" | head -1)
PREDICTION_END=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}" | tail -1)


var2=$(echo "${PREDICTION_END}" | cut -d " " -f 1)

MAXELEV=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')

while [ "$(date --date="@${var2}" +%D)" = "$(date +%D)" ]; do
	START_TIME=$(echo "$PREDICTION_START" | cut -d " " -f 3-4)
	var1=$(echo "$PREDICTION_START" | cut -d " " -f 1)
	var3=$(echo "$START_TIME" | cut -d " " -f 2 | cut -d ":" -f 3)
	TIMER=$(expr "${var2}" - "${var1}" + "${var3}")
	OUTDATE=$(date --date="TZ=\"UTC\" ${START_TIME}" +%Y%m%d-%H%M%S)

	if [ "${MAXELEV}" -gt "${SAT_MIN_ELEV}" ]
	then
		SATNAME=$(echo "$1" | sed "s/ //g")
		echo ${SATNAME} "${OUTDATE}" "$MAXELEV"
		echo "${NOAA_HOME}/receive_iss.sh \"${1}\" $2 ISS${OUTDATE} "${NOAA_HOME}"/predict/amateur.tle \
${var1} ${TIMER} ${MAXELEV}" | at "$(date --date="TZ=\"UTC\" ${START_TIME}" +"%H:%M %D")"
	fi
	NEXTPREDICT=$(expr "${var2}" + 60)
	PREDICTION_START=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}" "${NEXTPREDICT}" | head -1)
	PREDICTION_END=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}"  "${NEXTPREDICT}" | tail -1)
	MAXELEV=$(/usr/bin/predict -t "${NOAA_HOME}"/predict/amateur.tle -p "${1}" "${NEXTPREDICT}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}')
	var2=$(echo "${PREDICTION_END}" | cut -d " " -f 1)
done

