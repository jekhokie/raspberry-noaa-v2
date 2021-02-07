#!/bin/bash
#
# Purpose: Receive and process NOAA captures.

# run as a normal user
if [ $EUID -eq 0 ]; then
  log "This script shouldn't be run as root." "ERROR"
  exit 1
fi

# import common lib
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
SAT_NAME=$1
FILENAME_BASE=$2
TLE_FILE=$3
EPOCH_START=$4
CAPTURE_TIME=$5
SAT_MAX_ELEVATION=$6

# base directory plus filename helper variables
AUDIO_FILE_BASE="${NOAA_AUDIO_OUTPUT}/${FILENAME_BASE}"
IMAGE_FILE_BASE="${IMAGE_OUTPUT}/${FILENAME_BASE}"
IMAGE_THUMB_BASE="${IMAGE_OUTPUT}/thumb/${FILENAME_BASE}"

# pass start timestamp and sun elevation
PASS_START=$(expr "$EPOCH_START" + 90)
SUN_ELEV=$(python3 "$NOAA_HOME"/scripts/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an existing rtl_fm instance running, I quit" "ERROR"
  exit 1
fi

log "Starting rtl_fm record" "INFO"
${NOAA_HOME}/scripts/audio_recorders/record_noaa.sh "${SAT_NAME}" $CAPTURE_TIME "${RAMFS_AUDIO_BASE}.wav"

spectrogram=0
if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  spectrogram=1

  log "Producing spectrogram" "INFO"
  spectrogram_text="${START_DATE} @ ${SAT_MAX_ELEVATION}°"
  $SOX "${AUDIO_FILE_BASE}.wav" -n spectrogram -t "${SAT_NAME}" -x 1024 -y 257 -c "${spectrogram_text}" -o "${IMAGE_FILE_BASE}-spectrogram.png"
  $CONVERT -thumbnail 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png"
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
$WXMAP -T "${SAT_NAME}" -H "${TLE_FILE}" -p 0 ${extra_map_opts} -o "${epoch_adjusted}" "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"

# build images based on enhancements defined
for i in $ENHANCEMENTS; do
  log "Decoding image" "INFO"
  annotation="${SAT_NAME} $i ${START_DATE} Elev: $SAT_MAX_ELEVATION°"

  $WXTOIMG -o -m "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png" -e "$i" "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-$i.jpg"

  $CONVERT -quality 90 -format jpg "${IMAGE_FILE_BASE}-$i.jpg" -undercolor black -fill yellow -pointsize 18 -annotate +20+20 $annotation "${IMAGE_FILE_BASE}-$i.jpg"
  $CONVERT -thumbnail 300 "${IMAGE_FILE_BASE}-$i.jpg" "${IMAGE_THUMB_BASE}-$i.jpg"
done

rm "${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"

# store enhancements
if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME_BASE\", 1, 1, $spectrogram);"
else
  $SQLITE3 $DB_FILE "INSERT OR REPLACE INTO decoded_passes (pass_start, file_path, daylight_pass, sat_type, has_spectrogram) VALUES ($EPOCH_START, \"$FILENAME_BASE\", 0, 1, $spectrogram);"
fi

pass_id=$($SQLITE3 $DB_FILE "select id from decoded_passes order by id desc limit 1;")

$SQLITE3 $DB_FILE "update predict_passes set is_active = 0 where (predict_passes.pass_start) in (select predict_passes.pass_start from predict_passes inner join decoded_passes on predict_passes.pass_start = decoded_passes.pass_start where decoded_passes.id = $pass_id);"

if [ "$DELETE_AUDIO" = true ]; then
  log "Deleting audio files" "INFO"
  rm "${AUDIO_FILE_BASE}.wav"
fi
