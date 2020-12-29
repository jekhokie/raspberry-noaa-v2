#!/bin/bash
set -e

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa.conf"
. "$NOAA_HOME/common.sh"

datetime=$(date +"%Y%m%d-%H%M%S")

log "1/3: Backing up database" "INFO"
cp "$NOAA_HOME/panel.db" "$NOAA_HOME/panel.db.bak-$datetime"
log "1/3: Database backup done: panel.db.bak-$datetime" "INFO"

log "2/3: Creating new columns" "INFO"
set +e
sqlite3 "$NOAA_HOME/panel.db" "alter table decoded_passes add column img_count integer;"
sqlite3 "$NOAA_HOME/panel.db" "alter table decoded_passes add column sat_type integer;"
set -e
log "2/3: img_count and sat_type columns created" "INFO"


log "3/3: Migrating is_noaa column" "INFO"
sqlite3 "$NOAA_HOME/panel.db" "update decoded_passes set sat_type = is_noaa;"
log "3/3: is_noaa column migration done" "INFO"


log "4/3: Setting up SCHEDULE_ISS on .noaa.conf" "INFO"
set +e
if ! grep -q SCHEDULE_ISS "$HOME/.noaa.conf"; then
    echo "SCHEDULE_ISS=\"false\"" >> "$HOME/.noaa.conf"
    log "4/3: SCHEDULE_ISS is set now on .noaa.conf" "INFO"
else
    log "4/3: SCHEDULE_ISS was already set on .noaa.conf" "INFO"
fi
set -e

log "3/3: Updating PHP files" "INFO"
sudo cp "$NOAA_HOME/templates/webpanel/Model/Conn.php" "/var/www/wx/Model/Conn.php"
sudo cp "$NOAA_HOME/templates/webpanel/Views/V_viewLastImages.php" "/var/www/wx/Views/V_viewLastImages.php"
log "3/3: PHP files updated" "INFO"
