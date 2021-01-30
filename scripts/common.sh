#!/bin/bash

. "$HOME/.noaa-v2.conf"

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
log_level=${LOG_LEVEL}

# log function
log() {
  local log_message=$1
  local log_priority=$2

  #check if level exists
  [[ ${levels[$log_priority]} ]] || return 1

  #check if level is enough
  (( ${levels[$log_priority]} < ${levels[$log_level]} )) && return 2

  #log here
  echo "${log_priority} : ${log_message}"
}

## current date and folder structure
START_DATE=$(date '+%d-%m-%Y %H:%M')
