#!/bin/bash

## import common lib
. ~/common.sh

find "${NOAA_HOME}/map/" -type f -name '*.png' -mtime +1 -exec rm -f {} \;
log "${NOAA_HOME}/map/ folder pruned" "INFO"
find "${NOAA_OUTPUT}/audio/" -type f -name '*.wav' -mtime +1 -exec rm -f {} \;
log "${NOAA_OUTPUT}/audio/ folder pruned" "INFO"
