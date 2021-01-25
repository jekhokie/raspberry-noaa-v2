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

WEB_DIR=/var/www/wx
STEPS=3

echo "
      This script is used to sync webpanel updates and provide an easy
      way for users to keep their webpanel up to date with new features
      that are released - note that the first time you use this to migrate
      to the new webpanel contents, your Config.php file (containing locale
      settings) will be backed up to the $NOAA_HOME/bak/ directory and a
      replacement config.php put in its place. You can reference values you
      might have configured in the backup file to update $WEB_DIR/config.php
      to your liking.

      If you have made significant changes to any of the contents in the webpanel
      deployment, they likely WILL be destroyed by running this script as all
      files in $WEB_DIR are replaced with the exception of the following, which are
      left alone to preserve the captures:

        * audio/
        * images/
        * meteor/
"

read -rp "Are you sure you wish to proceed? (y/N) "
if [[ $REPLY =~ ^[Nn]$ ]]; then
  log "Aborting webpanel sync" "ERROR"
  exit 0
elif [[ $REPLY =~ ^[Yy]$ ]]; then
  log "Webpanel sync proceeding!" "INFO"
else
  log "Aborting webpanel sync - unknown option '$REPLY'" "ERROR"
  exit 1
fi

log "1/$STEPS: Backing up PHP config file..." "INFO"
if [ -f "$WEB_DIR/config.php" ]; then
    log "  Found newer-style config file - backing up." "INFO"
    cp $WEB_DIR/config.php $NOAA_HOME/bak/config.php.backup
elif [ -f "$WEB_DIR/Config.php" ]; then
    log "  Found older-style config file - backing up." "INFO"
    cp $WEB_DIR/Config.php $NOAA_HOME/bak/Config.php.backup
else
    log "  Did not find any existing config file - proceeding." "INFO"
fi
log "1/$STEPS: Done backing up PHP config file" "INFO"

log "2/$STEPS: Removing old PHP files (excluding images/audio)..." "INFO"
find $WEB_DIR/ -mindepth 1 -type d -name "images" -prune -o -type d -name "audio" -prune -o -type d -name "meteor" -prune -o -print | xargs rm -rf
log "2/$STEPS: Old PHP files removed" "INFO"

log "3/$STEPS: Copying new PHP files..." "INFO"
sudo cp -rp $NOAA_HOME/templates/webpanel/* $WEB_DIR/
log "3/$STEPS: Done copying new PHP files" "INFO"

log "Your old PHP config file has been copied to the bak/ directory" "INFO"
log "Please update any settings you wish to preserve in $WEB_DIR/config.php" "INFO"
log "  including 'lang' and 'timezone' settings for display" "INFO"
