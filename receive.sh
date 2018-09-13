#!/bin/sh

## debug
#set -x

. ~/.noaa.conf

## sane checks
if [ ! -d ${NOAA_HOME} ]; then
	mkdir -p ${NOAA_HOME}
fi

if [ ! -d ${NOAA_OUTPUT} ]; then
	mkdir -p ${NOAA_OUTPUT}
fi

if [ ! -d ${NOAA_OUTPUT}/audio/ ]; then
	mkdir -p ${NOAA_OUTPUT}/audio/
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

START_DATE=$(date '+%d-%m-%Y %H:%M')
timeout "${6}" rtl_fm -f "${2}"M -s 60k -g 50 -p 55 -E wav -E deemp -F 9 - | sox -t raw -e signed -c 1 -b 16 -r 60000 - ${NOAA_OUTPUT}/audio/"${3}".wav rate 11025

PASS_START=$(expr "$5" + 90)
/usr/local/bin/wxmap -T "${1}" -H "${4}" -p 0 -l 0 -o "${PASS_START}" ${NOAA_HOME}/map/"${3}"-map.png
for i in ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT; do
	/usr/local/bin/wxtoimg -o -m ${NOAA_HOME}/map/"${3}"-map.png -e $i ${NOAA_OUTPUT}/audio/"${3}".wav ${NOAA_OUTPUT}/image/"${3}"-$i.png
	/usr/bin/convert ${NOAA_OUTPUT}/image/"${3}"-$i.png -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} $i ${START_DATE}" ${NOAA_OUTPUT}/image/"${3}"-$i.png
done

ECLIPSED=$(identify -ping -format "%[fx:w]" /usr/share/html/image/$3-MSA.png)
if [ "$ECLIPSED" -gt 1041 ]; then
	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" ${NOAA_OUTPUT}/image/$3-MCIR-precip.png ${NOAA_OUTPUT}/image/$3-MCIR.png 
else
	python2 ${NOAA_HOME}/post.py "$1 ${START_DATE}" ${NOAA_OUTPUT}/image/$3-MCIR-precip.png ${NOAA_OUTPUT}/image/$3-MSA-precip.png ${NOAA_OUTPUT}/image/$3-HVC-precip.png ${NOAA_OUTPUT}/image/$3-HVCT.png 
fi

