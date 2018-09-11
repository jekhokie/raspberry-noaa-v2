#!/bin/bash
PREDICTION_START=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}" | head -1`
PREDICTION_END=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}" | tail -1`

var2=`echo $PREDICTION_END | cut -d " " -f 1`

MAXELEV=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

while [ `date --date="@${var2}" +%D` == `date +%D` ]; do
	START_TIME=`echo $PREDICTION_START | cut -d " " -f 3-4`
	var1=`echo $PREDICTION_START | cut -d " " -f 1`
	var3=`echo $START_TIME | cut -d " " -f 2 | cut -d ":" -f 3`
	TIMER=`expr $var2 - $var1 + $var3`
	OUTDATE=`date --date="TZ=\"UTC\" $START_TIME" +%Y%m%d-%H%M%S`
	if [ $MAXELEV -gt 19 ]
  		then
			echo ${1//" "}${OUTDATE} $MAXELEV
			echo "/home/pi/receive.sh \"${1}\" $2 ${1//" "}${OUTDATE} /home/pi/predict/weather.tle $var1 $TIMER" | at `date --date="TZ=\"UTC\" $START_TIME" +"%H:%M %D"`
	fi
	nextpredict=`expr $var2 + 60`
	PREDICTION_START=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}" $nextpredict | head -1`
	PREDICTION_END=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}"  $nextpredict | tail -1`
	MAXELEV=`/usr/bin/predict -t /home/pi/predict/weather.tle -p "${1}" $nextpredict | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`
	var2=`echo $PREDICTION_END | cut -d " " -f 1`
done
