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
STEPS=9

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
      moved to the public/ directory as part of this upgrade:

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

log "1/$STEPS: Checking for composer..." "INFO"
which composer
if [ $? -ne 0 ]; then
  sudo apt-get -y install composer
fi
log "1/$STEPS: Composer install/check done" "INFO"

log "2/$STEPS: Backing up PHP config file..." "INFO"
if [ -f "$WEB_DIR/config.php" ]; then
    log "  Found newer-style config file - backing up." "INFO"
    cp $WEB_DIR/config.php $NOAA_HOME/bak/config.php.backup
elif [ -f "$WEB_DIR/Config.php" ]; then
    log "  Found older-style config file - backing up." "INFO"
    cp $WEB_DIR/Config.php $NOAA_HOME/bak/Config.php.backup
else
    log "  Did not find any existing config file - proceeding." "INFO"
fi
log "2/$STEPS: Done backing up PHP config file" "INFO"

log "3/$STEPS: Removing old PHP files (excluding images/audio)..." "INFO"
find $WEB_DIR/ -mindepth 1 -type d -name "images" -prune -o -type d -name "audio" -prune -o -type d -name "meteor" -prune -o -print | xargs rm -rf
log "3/$STEPS: Old PHP files removed" "INFO"

log "4/$STEPS: Copying new PHP files..." "INFO"
sudo cp -rp $NOAA_HOME/templates/webpanel/* $WEB_DIR/
log "4/$STEPS: Done copying new PHP files" "INFO"

log "5/$STEPS: Moving audio, images, and meteor directories (if required/detected)..." "INFO"
new_path=/var/www/wx/public/
old_audio_path=/var/www/wx/audio
old_images_path=/var/www/wx/images
old_meteor_path=/var/www/meteor
if [ -d $old_audio_path ]; then
  if [ -d $new_path/audio ]; then
    log "Found new audio directory already exists - not moving old audio directory to avoid conflict (please handle yourself)" "ERROR"
  else
    log "Found old audio path, moving the directory to $new_path/audio" "INFO"
    mv $old_audio_path $new_path/audio
  fi
fi

if [ -d $old_images_path ]; then
  if [ -d $new_path/images ]; then
    log "Found new images directory already exists - not moving old images directory to avoid conflict (please handle yourself)" "ERROR"
  else
    log "Found old images path, moving the directory to $new_path/images" "INFO"
    mv $old_images_path $new_path/images
  fi
fi

if [ -d $old_meteor_path ]; then
  if [ -d $new_path/meteor ]; then
    log "Found new meteor directory already exists - not moving old meteor directory to avoid conflict (please handle yourself)" "ERROR"
  else
    log "Found old meteor path, moving the directory to $new_path/meteor" "INFO"
    mv $old_meteor_path $new_path/meteor
  fi
fi
log "5/$STEPS: Done moving audio, images, and meteor directories" "INFO"

log "6/$STEPS: Running composer to install dependencies..." "INFO"
composer install -d /var/www/wx/
log "6/$STEPS: Done running composer install" "INFO"

log "7/$STEPS: Aligning permissions..." "INFO"
chown -R pi:pi /var/www/wx/
log "8/$STEPS: Done aligning permissions" "INFO"

log "8/$STEPS: Updating nginx configuration (if required)..." "INFO"
echo "FILLMEIN - MOVE TO public/ AS ROOT DIR WITH REWRITES FOR index.php"
log "8/$STEPS: Done updating nginx configuration" "INFO"

log "9/$STEPS: Restarting nginx (if required)..." "INFO"
echo "FILLMEIN: RESTART NGINX ONLY IF REQUIRED"
log "9/$STEPS: Done restarting nginx" "INFO"

log "Your old PHP config file has been copied to the bak/ directory" "INFO"
log "Please update any settings you wish to preserve in $WEB_DIR/config.php" "INFO"
log "  including 'lang' and 'timezone' settings for display" "INFO"
