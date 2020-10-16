#!/bin/bash

## debug
# set -x

. "$HOME/.noaa.conf"

declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
log_level=${LOG_LEVEL}

## log function
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
FOLDER_DATE="$(date +%Y)/$(date +%m)/$(date +%d)"

## sane checks
if [ ! -d "${NOAA_HOME}" ]; then
	mkdir -m 775 -p "${NOAA_HOME}"
fi

if [ ! -d "${NOAA_OUTPUT}/audio/" ]; then
	mkdir -m 775 -p "${NOAA_OUTPUT}/audio/"
fi

if [ ! -d "${METEOR_OUTPUT}/audio/" ]; then
	mkdir -m 775 -p "${METEOR_OUTPUT}/audio/"
fi

if [ ! -d "${RAMFS_AUDIO}/audio/" ]; then
	mkdir -m 775 -p "${RAMFS_AUDIO}/audio/"
fi

if [ ! -d "${NOAA_OUTPUT}/image/" ]; then
	mkdir -m 775 -p "${NOAA_OUTPUT}/image/"
fi

if [ ! -d "${NOAA_HOME}/map/" ]; then
	mkdir -m 775 -p "${NOAA_HOME}/map/"
fi

if [ ! -d "${NOAA_HOME}/predict/" ]; then
	mkdir -m 775 -p "${NOAA_HOME}/predict/"
fi

if [ ! -d "${NOAA_OUTPUT}/image/${FOLDER_DATE}" ]; then
        mkdir -m 775 -p "${NOAA_OUTPUT}/image/${FOLDER_DATE}"
fi
