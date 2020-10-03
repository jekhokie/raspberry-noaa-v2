#!/bin/bash

## import common lib
. "$HOME/.noaa.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/common.sh"

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

log "Demodulation in progress (QPSK)" "INFO"
meteor_demod -B -o "${METEOR_OUTPUT}/${3}.qpsk" "${RAMFS_AUDIO}/audio/${3}.wav"

if [ "$DELETE_AUDIO" = true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO}/audio/${3}.wav"
else
	log "Moving audio files out to the SD card" "INFO"
    mv "${RAMFS_AUDIO}/audio/${3}.wav" "${NOAA_OUTPUT}/audio/${3}.wav"
fi

log "Decoding in progress (QPSK to BMP)" "INFO"
medet_arm "${METEOR_OUTPUT}/${3}.qpsk" "${METEOR_OUTPUT}/${3}" -cd

rm "${METEOR_OUTPUT}/${3}.qpsk"

if [ -f "${METEOR_OUTPUT}/${3}.dec" ]; then

    if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
        log "I got a successful ${3}.dec file. Decoding APID 68" "INFO"
        medet_arm "${METEOR_OUTPUT}/${3}.dec" "${METEOR_OUTPUT}/${3}-122" -r 68 -g 68 -b 68 -d
    else
        log "I got a successful ${3}.dec file. Creating false color image" "INFO"
        medet_arm "${METEOR_OUTPUT}/${3}.dec" "${METEOR_OUTPUT}/${3}-122" -r 65 -g 65 -b 64 -d
    fi

    log "Rectifying image to adjust aspect ratio" "INFO"
    python3 "${NOAA_HOME}/rectify.py" "${NOAA_OUTPUT}/images/${3}-122.bmp"
    rm "${METEOR_OUTPUT}/${3}-122.bmp"
    rm "${METEOR_OUTPUT}/${3}.bmp"

    sqlite3 /home/pi/raspberry-noaa/panel.db "insert into decoded_passes (pass_start, file_path, daylight_pass, is_noaa) values ($5,\"$3\", 1,0);"
    pass_id=$(sqlite3 /home/pi/raspberry-noaa/panel.db "select id from decoded_passes order by id desc limit 1;")
    if [ -n "$CONSUMER_KEY" ]; then
        log "Posting to Twitter" "INFO"
        python3 "${NOAA_HOME}/post.py" "$1 ${START_DATE} Resolución completa: https://weather.reyni.co/detail.php?id=$pass_id" "$7" "${NOAA_OUTPUT}/images/${3}-122-rectified.jpg"
    fi
    sqlite3 /home/pi/raspberry-noaa/panel.db "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"
else
    log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
