#!/bin/bash

## import common lib
. "$HOME/.noaa.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/common.sh"


SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
    log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
	RAMFS_AUDIO="${METEOR_OUTPUT}"
fi

## pass start timestamp and sun elevation
PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null
then
	log "There is an already running rtl_fm instance but I dont care for now, I prefer this pass" "INFO"
	pkill -9 -f rtl_fm
fi

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
# $7 = Satellite max elevation

log "Starting rtl_fm record" "INFO"
timeout "${6}" /usr/local/bin/rtl_fm ${BIAS_TEE} -M raw -f "${2}"M -s 288k -g 48 -p 1 | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav "${RAMFS_AUDIO}/audio/${3}.wav" rate 96k

log "Normalization in progress" "INFO"
sox "${RAMFS_AUDIO}/audio/${3}.wav" "${METEOR_OUTPUT}/${3}.wav" gain -n

log "Demodulation in progress (QPSK)" "INFO"
meteor_demod -B -o "${METEOR_OUTPUT}/${3}.qpsk" "${METEOR_OUTPUT}/${3}.wav"

if [ "$DELETE_AUDIO" = true ]; then
    log "Deleting audio files" "INFO"
    rm "${METEOR_OUTPUT}/audio/${3}.wav"
    rm "${RAMFS_AUDIO}/${3}.wav"
fi

log "Decoding in progress (QPSK to BMP)" "INFO"
medet_arm "${METEOR_OUTPUT}/${3}.qpsk" "${METEOR_OUTPUT}/${3}" -cd

rm "${METEOR_OUTPUT}/${3}.qpsk"

if [ -f "${METEOR_OUTPUT}/${3}.dec" ]; then

    if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
        log "I got a successful ${3}.dec file. Decoding APID 68" "INFO"
        medet_arm "${METEOR_OUTPUT}/${3}.dec" "${METEOR_OUTPUT}/${3}-122" -r 68 -g 68 -b 68 -d
        convert "${METEOR_OUTPUT}/${3}-122.bmp" -channel RGB -negate "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.png"
    else
        log "I got a successful ${3}.dec file. Creating false color image" "INFO"
        medet_arm "${METEOR_OUTPUT}/${3}.dec" "${METEOR_OUTPUT}/${3}-122" -r 65 -g 65 -b 64 -d
        convert "${METEOR_OUTPUT}/${3}-122.bmp" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.png"
    fi
    log "Rectifying image to adjust aspect ratio" "INFO"
    python3 "${NOAA_HOME}/rectify.py" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.png"
    convert "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified.png" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${1} ${START_DATE} Elevation: $7Â°" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified-text.png"
    if [ -n "$CONSUMER_KEY" ]; then
        log "Posting to Twitter" "INFO"
        python3 "${NOAA_HOME}/post.py" "$1 EXPERIMENTAL ${START_DATE} Resolución completa: http://weather.reyni.co/image/${FOLDER_DATE}/${3}-122-rectified.jpg" "$7°" "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified.png"
    fi
    rm "${METEOR_OUTPUT}/${3}.bmp"
    rm "${METEOR_OUTPUT}/${3}-122.bmp"
    rm "${METEOR_OUTPUT}/${3}-122.png"
    rm "${METEOR_OUTPUT}/${3}.dec"
    rm "${METEOR_OUTPUT}/${3}-122.png"
    rm "${METEOR_OUTPUT}/${3}-122-rectified.png"
    rm "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122.png"
    rm "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified.png"
    #rm "${NOAA_OUTPUT}/image/${FOLDER_DATE}/${3}-122-rectified-text.png"
else
    log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
