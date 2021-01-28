#!/bin/bash
set -e

### Run as a normal user
if [ $EUID -eq 0 ]; then
    echo "This script shouldn't be run as root."
    exit 1
fi

## import common lib
. "$HOME/.noaa.conf"
. "$NOAA_HOME/scripts/common.sh"

if [ -f "$NOAA_HOME/demod.py" ]; then
    log "Seems like you already have run this migration before" "ERROR"
    exit 1
fi

if [ ! -f "$DB_HOME/panel.db" ]; then
    log "Seems like there's no db/panel.db database in your project folder" "ERROR"
    exit 1
fi

STEPS="6"

datetime=$(date +"%Y%m%d-%H%M%S")

log "1/$STEPS: Backing up database" "INFO"
cp "$DB_HOME/panel.db" "$DB_HOME/panel.db.bak-$datetime"
log "1/$STEPS: Database backup done: panel.db.bak-$datetime" "INFO"

log "2/$STEPS: Creating new columns" "INFO"
set +e
sqlite3 "$DB_HOME/panel.db" "alter table decoded_passes add column img_count integer;"
sqlite3 "$DB_HOME/panel.db" "alter table decoded_passes add column sat_type integer;"
set -e
log "2/$STEPS: img_count and sat_type columns created" "INFO"


log "3/$STEPS: Migrating is_noaa column" "INFO"
sqlite3 "$DB_HOME/panel.db" "update decoded_passes set sat_type = is_noaa;"
log "3/$STEPS: is_noaa column migration done" "INFO"


log "4/$STEPS: Setting up SCHEDULE_ISS on .noaa.conf" "INFO"
set +e
if ! grep -q SCHEDULE_ISS "$HOME/.noaa.conf"; then
    echo "SCHEDULE_ISS=\"false\"" >> "$HOME/.noaa.conf"
    log "4/$STEPS: SCHEDULE_ISS is set now on .noaa.conf" "INFO"
else
    log "4/$STEPS: SCHEDULE_ISS was already set on .noaa.conf" "INFO"
fi
set -e

log "5/$STEPS: Updating PHP files" "INFO"
sudo cp "$NOAA_HOME/templates/webpanel/Model/Conn.php" "/var/www/wx/Model/Conn.php"
sudo cp "$NOAA_HOME/templates/webpanel/Views/V_viewLastImages.php" "/var/www/wx/Views/V_viewLastImages.php"
log "5/$STEPS: PHP files updated" "INFO"


log "6/$STEPS: Installing pd120_decoder" "INFO"
if [ -f "$NOAA_HOME/demod.py" ]; then
    log "6/$STEPS: pd120_decoder already installed" "INFO"
else
    wget -qr https://github.com/reynico/pd120_decoder/archive/master.zip -O /tmp/master.zip
    (
        cd /tmp
        unzip master.zip
        cd pd120_decoder-master/pd120_decoder/
        pip3 install --user -r requirements.txt
        cp "{demod.py,utils.py}" "$NOAA_HOME"
    )
    log "6/$STEPS: pd120_decoder installed" "INFO"
fi
