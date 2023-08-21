#!/bin/bash
#
# Purpose: Common code that is likely loaded in most of the scripts
#          within this framework. Handles things such as a start date/time,
#          logging, and other various "common" functionality.

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
log_level=${LOG_LEVEL}

# log function
log() {
  local log_message=$1
  local log_priority=$2

  # check if level exists and is of the right level to log
  [[ ${levels[$log_priority]} ]] || return 1
  (( ${levels[$log_priority]} < ${levels[$log_level]} )) && return 2

  # log in place (which for at jobs end up in the linux mail)
  echo "${log_priority} : ${log_message}"

  # log output to a log file
  echo $(date '+%d-%m-%Y %H:%M') $0 "${log_priority} : ${log_message}" >> "$NOAA_LOG"
}

# run as a normal user for any scripts within
if [ $EUID -eq 0 ]; then
  log "This script shouldn't be run as root." "ERROR"
  exit 1
fi

# binary helpers
CONVERT="/usr/bin/convert"
FFMPEG="/usr/bin/ffmpeg"
GMIC="/usr/bin/gmic"
IDENTIFY="/usr/bin/identify"
METEOR_DEMOD="/usr/local/bin/meteor_demod"
PREDICT="/usr/bin/predict"
RTL_FM="/usr/local/bin/rtl_fm"
SOX="/usr/bin/sox"
SQLITE3="/usr/bin/sqlite3"
WXMAP="/usr/local/bin/wxmap"
WXTOIMG="/usr/local/bin/wxtoimg"
WKHTMLTOIMG="/usr/local/bin/wkhtmltoimage"
METEORDEMOD="/usr/bin/meteordemod"
SATDUMP="/usr/bin/satdump"

# base directories for scripts
SCRIPTS_DIR="${NOAA_HOME}/scripts"
AUDIO_PROC_DIR="${SCRIPTS_DIR}/audio_processors"
IMAGE_PROC_DIR="${SCRIPTS_DIR}/image_processors"
PUSH_PROC_DIR="${SCRIPTS_DIR}/push_processors"

# frequency ranges for objects
METEOR_FREQ="137.9000"
NOAA15_FREQ="137.6200"
NOAA18_FREQ="137.9125"
NOAA19_FREQ="137.1000"

# current date and time
export START_DATE=$(date '+%d-%m-%Y %H:%M')
