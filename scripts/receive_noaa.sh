#!/bin/bash
#
# Purpose: Receive and process NOAA captures.
#
# Input parameters:
#   1. Name of satellite (e.g. "NOAA 18")
#   2. Filename of image outputs
#   3. TLE file location
#   4. Epoch start time for capture
#   5. Duration of capture (seconds)
#   6. Max angle elevation for satellite
#
# Example:
#   ./receive_noaa.sh "NOAA 18" NOAA1820210208-194829 ./orbit.tle 1612831709 919 31

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
capture_start=$START_DATE

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
SUN_ELEV=$(python3 "$SCRIPTS_DIR"/sun.py "$PASS_START")

if pgrep "rtl_fm" > /dev/null; then
  log "There is an existing rtl_fm instance running, I quit" "ERROR"
  exit 1
fi

log "Starting rtl_fm record" "INFO"
${AUDIO_PROC_DIR}/noaa_record.sh "${SAT_NAME}" $CAPTURE_TIME "${AUDIO_FILE_BASE}.wav" >> $NOAA_LOG 2>&1

spectrogram=0
if [[ "${PRODUCE_SPECTROGRAM}" == "true" ]]; then
  log "Producing spectrogram" "INFO"
  spectrogram=1
  spectro_text="${capture_start} @ ${SAT_MAX_ELEVATION}°"
  ${IMAGE_PROC_DIR}/spectrogram.sh "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-spectrogram.png" "${SAT_NAME}" spectro_text
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-spectrogram.png" "${IMAGE_THUMB_BASE}-spectrogram.png"
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
map_overlay="${NOAA_HOME}/tmp/map/${FILENAME_BASE}-map.png"
$WXMAP -T "${SAT_NAME}" -H "${TLE_FILE}" -p 0 ${extra_map_opts} -o "${epoch_adjusted}" $map_overlay >> $NOAA_LOG 2>&1

# determine which enhancements to create based on sunlight/dark
if [ "${SUN_ELEV}" -gt "${SUN_MIN_ELEV}" ]; then
  ENHANCEMENTS="ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT therm"
  daylight="true"
else
  ENHANCEMENTS="ZA MCIR MCIR-precip therm"
  daylight="false"
fi

# build images based on enhancements defined
for enhancement in $ENHANCEMENTS; do
  log "Decoding image" "INFO"
  annotation="${SAT_NAME} $enhancement ${capture_start} Elev: $SAT_MAX_ELEVATION°"

  # determine what frequency based on NOAA variant
  proc_script=""
  case $enhancement in
    "ZA")
      proc_script="noaa_za.sh"
      ;;
    "MCIR")
      proc_script="noaa_mcir.sh"
      ;;
    "MCIR-precip")
      proc_script="noaa_mcir_precip.sh"
      ;;
    "MSA")
      proc_script="noaa_msa.sh"
      ;;
    "MSA-precip")
      proc_script="noaa_msa_precip.sh"
      ;;
    "HVC")
      proc_script="noaa_hvc.sh"
      ;;
    "HVC-precip")
      proc_script="noaa_hvc_precip.sh"
      ;;
    "HVCT")
      proc_script="noaa_hvct.sh"
      ;;
    "HVCT-precip")
      proc_script="noaa_hvct_precip.sh"
      ;;
    "therm")
      proc_script="noaa_therm.sh"
      ;;
  esac

  if [ -z "${proc_script}" ]; then
    log "No image processor found for $enhancement - skipping." "ERROR"
  else
    ${IMAGE_PROC_DIR}/${proc_script} $map_overlay "${AUDIO_FILE_BASE}.wav" "${IMAGE_FILE_BASE}-$enhancement.jpg" >> $NOAA_LOG 2>&1
  fi

  ${IMAGE_PROC_DIR}/noaa_normalize_annotate.sh "${IMAGE_FILE_BASE}-$enhancement.jpg" "${annotation}" 90 >> $NOAA_LOG 2>&1
  ${IMAGE_PROC_DIR}/thumbnail.sh 300 "${IMAGE_FILE_BASE}-$enhancement.jpg" "${IMAGE_THUMB_BASE}-$enhancement.jpg" >> $NOAA_LOG 2>&1
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
