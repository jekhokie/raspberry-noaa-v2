#!/bin/sh

## debug
# set -x

. ~/.noaa.conf

find ${NOAA_HOME}/map/ -type f -name '*.png' -mtime +2 -exec rm -f {} \;
find ${NOAA_OUTPUT}/audio/ -type f -name '*.wav' -mtime +2 -exec rm -f {} \;
