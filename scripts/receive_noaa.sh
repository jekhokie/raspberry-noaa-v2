#!/bin/bash

# run as a normal user
if [ $EUID -eq 0 ]; then
  echo "This script shouldn't be run as root."
  exit 1
fi

# import common lib
. "$HOME/.noaa-v2.conf"
. "$HOME/.tweepy.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
SAT_NAME=$1
FREQ=$2
FILENAME_BASE=$3
TLE_FILE=$4
EPOCH_START=$5
CAPTURE_TIME=$6
SAT_MAX_ELEVATION=$7

# base directory plus filename_base for re-use
FILENAME="${NOAA_AUDIO_OUTPUT}/${FILENAME_BASE}"

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/scripts/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an existing rtl_fm instance running, I quit" "ERROR"
  exit 1
fi

log "Starting rtl_fm record" "INFO"
timeout "${CAPTURE_TIME}" /usr/local/bin/rtl_fm ${BIAS_TEE} -f "${FREQ}"M -s 60k -g $GAIN -E wav -E deemp -F 9 - | /usr/bin/sox -t raw -e signed -c 1 -b 16 -r 60000 - "${FILENAME}.wav" rate 11025

spectrogram=0
if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  log "Producing spectrogram" "INFO"
  spectrogram=1
  spectrogram_text="${START_DATE} @ ${SAT_MAX_ELEVATION}°"
  sox "${FILENAME}.wav" -n spectrogram -t "${SAT_NAME}" -x 1024 -y 257 -c "${spectrogram_text}" -o "${IMAGE_OUTPUT}/${FILENAME_BASE}-spectrogram.png"
  /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME_BASE}-spectrogram.png" "${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}-spectrogram.png"
fi

if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
  ENHANCEMENTS="ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT"
  daylight="true"
else
  ENHANCEMENTS="ZA MCIR MCIR-precip"
  daylight="false"
fi

log "Bulding pass map" "INFO"
# add 10 seconds to ensure we account for small deviations in timing - being even a second too soon
# can cause an error of "wxmap: warning: could not find matching pass to build overlay map.", while
# going over the start time by a few seconds while still being within the pass timing causes wxmap
# to track *back* to the start of the pass
epoch_adjusted=$(($PASS_START + 10))

# calculate any extra map options such as crosshair for base station, coloring, etc.
extra_map_opts=""
if [ "${NOAA_MAP_CROSSHAIR_ENABLE}" == "true" ]; then
  extra_map_opts="${extra_map_opts} -l 1 -c l:${NOAA_MAP_CROSSHAIR_COLOR}"
fi
if [ "${NOAA_MAP_GRID_DEGREES}" != "0.0" ]; then
  extra_map_opts="${extra_map_opts} -g ${NOAA_MAP_GRID_DEGREES} -c g:${NOAA_MAP_GRID_COLOR}"
fi

# build overlay map
/usr/local/bin/wxmap -T "${SAT_NAME}" -H "${TLE_FILE}" -p 0 ${extra_map_opts} -o "${epoch_adjusted}" "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"

# build images based on enhancements defined
for i in $ENHANCEMENTS; do
  log "Decoding image" "INFO"
  /usr/local/bin/wxtoimg -o -m "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png" -e "$i" "${FILENAME}.wav" "${IMAGE_OUTPUT}/${FILENAME_BASE}-$i.jpg"
  /usr/bin/convert -quality 90 -format jpg "${IMAGE_OUTPUT}/${FILENAME_BASE}-$i.jpg" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "${SAT_NAME} $i ${START_DATE} Elev: $SAT_MAX_ELEVATION°" "${IMAGE_OUTPUT}/${FILENAME_BASE}-$i.jpg"
  /usr/bin/convert -thumbnail 300 "${IMAGE_OUTPUT}/${FILENAME_BASE}-$i.jpg" "${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}-$i.jpg"
done

rm "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"

# store enhancements
if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
  sqlite3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME_BASE\", 1, 1, $spectrogram);"
else
  sqlite3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME_BASE\", 0, 1, $spectrogram);"
fi

pass_id=$(sqlite3 $DB_FILE "select id from decoded_passes order by id desc limit 1;")

if [ -n "$CONSUMER_KEY" ]; then
  log "Posting to Twitter" "INFO"
  if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
    python3 "${NOAA_HOME}/scripts/post.py" "$SAT_NAME ${START_DATE} Mas imagenes: https://weather.reyni.co/detail.php?id=$pass_id" "$SAT_MAX_ELEVATION" "${IMAGE_OUTPUT}/$FILENAME_BASE-MCIR-precip.jpg" "${IMAGE_OUTPUT}/$FILENAME_BASE-MSA-precip.jpg" "${IMAGE_OUTPUT}/$FILENAME_BASE-HVC-precip.jpg" "${IMAGE_OUTPUT}/$FILENAME_BASE-HVCT-precip.jpg"
  else
    python3 "$NOAA_HOME/scripts/post.py" "$SAT_NAME ${START_DATE} Mas imagenes: https://weather.reyni.co/detail.php?id=$pass_id" "$SAT_MAX_ELEVATION" "${IMAGE_OUTPUT}/$FILENAME_BASE-MCIR-precip.jpg" "${IMAGE_OUTPUT}/$FILENAME_BASE-MCIR.jpg"
  fi
fi

sqlite3 $DB_FILE "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

if [ "$DELETE_AUDIO" = true ]; then
  log "Deleting audio files" "INFO"
  rm "${FILENAME}.wav"
fi
