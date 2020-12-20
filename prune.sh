#!/bin/bash

## import common lib
. "$HOME/.noaa.conf"
. "$NOAA_HOME/common.sh"

for img_path in $(sqlite3 ${NOAA_HOME}/panel.db "select file_path from decoded_passes limit 10;"); do
    find "${NOAA_OUTPUT}/images/" -type f -name "${IMG_NAME}*.jpg" -exec rm -f {} \;
    find "${NOAA_OUTPUT}/images/thumb/" -type f -name "${IMG_NAME}*.jpg" -exec rm -f {} \;
    log "${img_path} file pruned" "INFO"
    sqlite3 "${NOAA_HOME}/panel.db" "delete from decoded_passes where file_path = \"$img_path\";"
    log "Database entry pruned" "INFO"
done
