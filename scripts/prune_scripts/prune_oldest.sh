#!/bin/bash
#
# Purpose: Prunes (removes) the $PRUNE_OLDEST number of oldest captures, including
#          database records and associated images/files on disk.

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

log "Pruning captures..." "INFO"
for img_path in $(sqlite3 ${DB_FILE} "select file_path from decoded_passes limit ${PRUNE_OLDEST};"); do
  find "${IMAGE_OUTPUT}/" -maxdepth 1 -type f -name "${img_path}*.jpg" -delete;
  find "${IMAGE_OUTPUT}/" -maxdepth 1 -type f -name "${img_path}*.png" -delete;
  find "${IMAGE_OUTPUT}/thumb/" -maxdepth 1 -type f -name "${img_path}*.jpg" -delete;
  find "${IMAGE_OUTPUT}/thumb/" -maxdepth 1 -type f -name "${img_path}*.png" -delete;
  log "  ${img_path} file pruned" "INFO"
  sqlite3 "${DB_FILE}" "delete from decoded_passes where file_path = \"$img_path\";"
  log "  Database entry pruned" "INFO"
done
