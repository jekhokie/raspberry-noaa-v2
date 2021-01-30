#!/bin/bash

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa-v2.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/scripts/common.sh"

in_mem=true
SYSTEM_MEMORY=$(free -m | awk '/^Mem:/{print $2}')
if [ "$SYSTEM_MEMORY" -lt 2000 ]; then
  log "The system doesn't have enough space to store a Meteor pass on RAM" "INFO"
  RAMFS_AUDIO="${METEOR_AUDIO_OUTPUT}"
  in_mem=false
fi

if [ "$FLIP_METEOR_IMG" == "true" ]; then
    log "I'll flip this image pass because FLIP_METEOR_IMG is set to true" "INFO"
    FLIP="-rotate 180"
else
    FLIP=""
fi

## pass start timestamp and sun elevation
PASS_START=$(expr "$5" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/scripts/sun.py "$PASS_START")

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
timeout "${6}" /usr/local/bin/rtl_fm ${BIAS_TEE} -M raw -f "${2}"M -s 288k -g $GAIN | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav "${RAMFS_AUDIO}/${3}.wav" rate 96k

log "Demodulation in progress (QPSK)" "INFO"
meteor_demod -B -o "${NOAA_HOME}/tmp/meteor/${3}.qpsk" "${RAMFS_AUDIO}/${3}.wav"

if [ "$DELETE_AUDIO" = true ]; then
    log "Deleting audio files" "INFO"
    rm "${RAMFS_AUDIO}/${3}.wav"
else
    if [ "$in_mem" == "true" ]; then
        log "Moving audio files out to the SD card" "INFO"
        mv "${RAMFS_AUDIO}/${3}.wav" "${METEOR_AUDIO_OUTPUT}/${3}.wav"
        rm "${RAMFS_AUDIO}/${3}.wav"
    fi
fi

log "Decoding in progress (QPSK to BMP)" "INFO"
medet_arm "${NOAA_HOME}/tmp/meteor/${3}.qpsk" "${METEOR_AUDIO_OUTPUT}/${3}" -cd

rm "${NOAA_HOME}/tmp/meteor/${3}.qpsk"

if [ -f "${METEOR_AUDIO_OUTPUT}/${3}.dec" ]; then
    if [ "${SUN_ELEV}" -lt "${SUN_MIN_ELEV}" ]; then
        log "I got a successful ${3}.dec file. Decoding APID 68" "INFO"
        medet_arm "${METEOR_AUDIO_OUTPUT}/${3}.dec" "${IMAGE_OUTPUT}/${3}-122" -r 68 -g 68 -b 68 -d
        /usr/bin/convert $FLIP -negate "${IMAGE_OUTPUT}/${3}-122.bmp" "${IMAGE_OUTPUT}/${3}-122.bmp"
    else
        log "I got a successful ${3}.dec file. Creating false color image" "INFO"
        medet_arm "${METEOR_AUDIO_OUTPUT}/${3}.dec" "${IMAGE_OUTPUT}/${3}-122" -r 65 -g 65 -b 64 -d
    fi

    log "Rectifying image to adjust aspect ratio" "INFO"
    python3 "${NOAA_HOME}/scripts/rectify.py" "${IMAGE_OUTPUT}/${3}-122.bmp"
    convert "${IMAGE_OUTPUT}/${3}-122-rectified.jpg" -channel rgb -normalize -undercolor black -fill yellow -pointsize 60 -annotate +20+60 "${1} ${START_DATE} Elev: $7°" "${IMAGE_OUTPUT}/${3}-122-rectified.jpg"
    /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${3}-122-rectified.jpg" "${IMAGE_OUTPUT}/thumb/${3}-122-rectified.jpg"
    rm "${IMAGE_OUTPUT}/${3}-122.bmp"
    rm "${METEOR_AUDIO_OUTPUT}/${3}.bmp"
    rm "${METEOR_AUDIO_OUTPUT}/${3}.dec"

    sqlite3 $DB_FILE "insert into decoded_passes (pass_start, file_path, daylight_pass, sat_type) values ($5,\"$3\", 1,0);"
    pass_id=$(sqlite3 $DB_FILE "select id from decoded_passes order by id desc limit 1;")
    if [ -n "$CONSUMER_KEY" ]; then
        log "Posting to Twitter" "INFO"
        python3 $NOAA_HOME/scripts/post.py "$1 ${START_DATE} Resolución completa: https://weather.reyni.co/detail.php?id=$pass_id" "$7" "${IMAGE_OUTPUT}/${3}-122-rectified.jpg"
    fi
    sqlite3 $DB_FILE "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"
else
    log "Decoding failed, either a bad pass/low SNR or a software problem" "ERROR"
fi
