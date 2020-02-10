#!/bin/sh

## debug
# set -x

. ~/.noaa.conf

## sane checks
if [ ! -d "${NOAA_HOME}" ]; then
	mkdir -p "${NOAA_HOME}"
fi

if [ ! -d "${NOAA_OUTPUT}" ]; then
	mkdir -p "${NOAA_OUTPUT}"
fi

if [ ! -d "${METEOR_OUTPUT}" ]; then
	mkdir -p "${METEOR_OUTPUT}"
fi

if [ ! -d "${NOAA_AUDIO}/audio/" ]; then
	mkdir -p "${NOAA_AUDIO}/audio/"
fi

if [ ! -d "${NOAA_OUTPUT}/image/" ]; then
	mkdir -p "${NOAA_OUTPUT}/image/"
fi

if [ ! -d "${NOAA_HOME}/map/" ]; then
	mkdir -p "${NOAA_HOME}/map/"
fi

if [ ! -d "${NOAA_HOME}/predict/" ]; then
	mkdir -p "${NOAA_HOME}/predict/"
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

if [ ! -d "${NOAA_OUTPUT}/image/${FOLDER_DATE}" ]; then
        mkdir -p "${NOAA_OUTPUT}/image/${FOLDER_DATE}"
fi

timeout 660 /usr/local/bin/rtl_fm -M raw -f 137.1M -s 288k -g 48 -p 1 | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav "${NOAA_AUDIO}/audio/${3}.wav" rate 96k

sox "${NOAA_AUDIO}/audio/${3}.wav" "${METEOR_OUTPUT}/${3}.wav" gain -n

rm "${NOAA_AUDIO}/audio/${3}.wav"

meteor_demod -B -o "${METEOR_OUTPUT}/${3}.qpsk" "${METEOR_OUTPUT}/${3}.wav"

medet_arm "${METEOR_OUTPUT}/${3}.qpsk" "${METEOR_OUTPUT}/${3}" -cd

if [ -f "${METEOR_OUTPUT}/${3}.dec" ]; then
    medet_arm "${METEOR_OUTPUT}/${3}.dec" "${METEOR_OUTPUT}/${3}-122" -r 65 -g 65 -b 64 -d
    convert "${METEOR_OUTPUT}/${3}-122.bmp" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.jpg"
    python3 "${NOAA_HOME}/rectify.py" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.jpg"
    rm "${METEOR_OUTPUT}/${3}-122.bmp"
    python3 "${NOAA_HOME}/post.py" "$1 EXPERIMENTAL ${START_DATE}" "$7" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified.jpg"
fi

