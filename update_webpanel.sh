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

STEPS=9

echo "
      This script is used to sync webpanel updates and provide an easy
      way for users to keep their webpanel up to date with new features
      that are released - note that this script is opinionated in the way
      the repository functions, so if you've customized beyond what the
      repo provides, use this at your own risk!

      Again, if you have made significant changes to any of the contents in the webpanel
      deployment, they likely WILL be destroyed by running this script as all
      files in $WEB_HOME are replaced with the exception of the following under
      the public/ directory:

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
if [ -f "$WEB_HOME/App/Config.php" ]; then
    cp $WEB_HOME/App/Config.php $NOAA_HOME/bak/Config.php.backup
    log "  Backed up config file to $NOAA_HOME/bak/Config.php.backup" "INFO"
else
    log "  Did not find any existing config file - proceeding." "INFO"
fi
log "2/$STEPS: Done backing up PHP config file" "INFO"

log "3/$STEPS: Removing old PHP files (excluding images/audio)..." "INFO"
find $WEB_HOME/ -mindepth 1 -type d -name "images" -prune -o -type d -name "audio" -prune -o -type d -name "meteor" -prune -o -print | xargs rm -rf
log "3/$STEPS: Old PHP files removed" "INFO"

log "4/$STEPS: Copying new PHP files..." "INFO"
sudo cp -rp $NOAA_HOME/templates/webpanel/* $WEB_HOME/
log "4/$STEPS: Done copying new PHP files" "INFO"

log "6/$STEPS: Running composer to install dependencies..." "INFO"
composer install -d $WEB_HOME/
log "6/$STEPS: Done running composer install" "INFO"

log "7/$STEPS: Aligning permissions..." "INFO"
chown -R pi:pi $WEB_HOME/
log "8/$STEPS: Done aligning permissions" "INFO"

log "Your old PHP config file has been copied to the bak/ directory in $NOAA_HOME" "INFO"
log "Please update any settings you wish to preserve in $WEB_HOME/App/Config.php" "INFO"
