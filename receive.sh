#!/bin/sh

## debug
# set -x

. ~/.noaa.conf

## sane checks
if [ ! -d ${NOAA_HOME} ]; then
	mkdir -p ${NOAA_HOME}
fi

if [ ! -d ${NOAA_OUTPUT} ]; then
	mkdir -p ${NOAA_OUTPUT}
fi

if [ ! -d ${NOAA_AUDIO}/audio/ ]; then
	mkdir -p ${NOAA_AUDIO}/audio/
fi

if [ ! -d ${NOAA_OUTPUT}/image/ ]; then
	mkdir -p ${NOAA_OUTPUT}/image/
fi

if [ ! -d ${NOAA_HOME}/map/ ]; then
	mkdir -p ${NOAA_HOME}/map/
fi

if [ ! -d ${NOAA_HOME}/predict/ ]; then
	mkdir -p ${NOAA_HOME}/predict/
fi

if pgrep "rtl_fm" > /dev/null
then
	exit 1
fi

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

START_DATE=$(date '+%d-%m-%Y %H:%M')
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"
timeout "${6}" /usr/local/bin/rtl_fm -f "${2}"M -s 60k -g 50 -p 55 -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 60000 - ${NOAA_AUDIO}/audio/"${3}".wav rate 11025

PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python2 sun.py $PASS_START)

if [ ! -d ${NOAA_OUTPUT}/image/${FOLDER_DATE} ]; then
	mkdir -p ${NOAA_OUTPUT}/image/${FOLDER_DATE}
fi

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
	ENHANCEMENTS="ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT"
else
	ENHANCEMENTS="ZA MCIR MCIR-precip"
fi

/usr/local/bin/wxmap -T "${1}" -H "${4}" -p 0 -l 0 -o "${PASS_START}" ${NOAA_HOME}/map/"${3}"-map.png
for i in $ENHANCEMENTS; do
	/usr/local/bin/wxtoimg -o -m ${NOAA_HOME}/map/"${3}"-map.png -e $i ${NOAA_AUDIO}/audio/"${3}".wav ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
	/usr/bin/convert -quality 90 -format jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
	/usr/bin/gdrive upload --parent 1gehY-0iYkNSkBU9RCDsSTexRaQ_ukN0A ${NOAA_OUTPUT}/image/${FOLDER_DATE}/"${3}"-$i.jpg
done

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MSA-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVC-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-HVCT-precip.jpg 
else
	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" "$7" ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR-precip.jpg ${NOAA_OUTPUT}/image/${FOLDER_DATE}/$3-MCIR.jpg 
fi
