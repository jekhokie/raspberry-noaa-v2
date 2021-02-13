#!/bin/bash
#
# Purpose: Perform backup of database - expected to run on a daily basis. Will
#          perform a backup of the database followed by delete any backups present
#          that are older than 3 days old (reasonable retention).

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

#Generate date since epoch in seconds - days
dt=$(date +"%Y%m%d")

log "Backing up database..." "INFO"
$SQLITE3 "${NOAA_HOME}/db/panel.db" ".backup '$NOAA_HOME/db_backups/panel.db.$dt.backup'"

log "Pruning database backups older than 3 days..." "INFO"
find "${NOAA_HOME}/db_backups/" -type f -mtime +3 -name panel.db.*.backup
