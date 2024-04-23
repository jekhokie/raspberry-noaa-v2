#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

die() {
  >&2 echo "${RED}Error: $1${RESET}" && exit 1
}

log_running() {
  echo " ${YELLOW}* $1${RESET}"
}

log_done() {
  echo " ${GREEN}✓ $1${RESET}"
}

log_finished() {
  echo " ${GREEN}$1${RESET}"
}

# run as a normal user
if [ $EUID -eq 0 ]; then
  die "Don't use sudo when running this script, quitting..."
fi

# verify the repo exists as expected in the home directory
if [ ! -e "$HOME/raspberry-noaa-v2" ]; then
  die "Please clone https://github.com/jekhokie/raspberry-noaa-v2 to your home directory"
fi

# check if this is a new install or an upgrade based on modprobe settings
# which is likey a safe way to tell if the user has already installed
# tools and rebooted
install_type='install'
if [ -f /etc/modprobe.d/rtlsdr.conf ]; then
  install_type='upgrade'
fi

log_running "Installing yaml and jsonschema Python modules..."
sudo apt install python3-yaml python3-jsonschema -y

log_running "Checking configuration files..."
python3 scripts/tools/validate_yaml.py config/settings.yml config/settings_schema.json
if [ $? -eq 0 ]; then
  log_done "  Config check complete!"
else
  die "  Please update your config/settings.yml file to accommodate the above errors"
fi

# install ansible
which ansible-playbook 2>&1 >/dev/null
if [ $? -ne 0 ]; then
  log_running "Updating and installing Ansible..."
  sudo apt update -yq
  sudo apt install -yq ansible

  if [ $? -eq 0 ]; then
    log_done "  Ansible install complete!"
  else
    die "  Could not install Ansible - please inspect the logs above"
  fi
fi

log_running "Checking for configuration settings..."
if [ -f config/settings.yml ]; then
  log_done "  Settings file ready!"
else
  die "  No settings file detected - please copy config/settings.yml.sample to config/settings.yml and edit for your environment"
fi

log_running "Checking pip packages..."
v_envbash=`pip list | grep envbash | wc -l`
if [ $v_envbash -eq 0 ]; then
  pip install envbash==1.2.0 --break-system-packages
  if [ $? -gt 0 ]; then
    die "  Something failed with the install - please inspect the logs above"
  fi
fi

v_facebooksdk=`pip list | grep facebook-sdk | wc -l`
if [ $v_facebooksdk -eq 0 ]; then
  pip install facebook-sdk==3.1.0 --break-system-packages
  if [ $? -gt 0 ]; then
    die "  Something failed with the install - please inspect the logs above"
  fi
fi

v_pysqlite3=`pip list | grep pysqlite3 | wc -l`
if [ $v_pysqlite3 -eq 0 ]; then
  pip install pysqlite3==0.5.2 --break-system-packages
  if [ $? -gt 0 ]; then
    die "  Something failed with the install - please inspect the logs above"
  fi
fi

log_running "Configure ATRM rule and PHP Controller based on scheduling user..."
if [ $? -eq 0 ]; then
   chmod +x $HOME/raspberry-noaa-v2/scripts/tools/atrm_rule_and_removal.sh
   $HOME/raspberry-noaa-v2/scripts/tools/atrm_rule_and_removal.sh
else
  die "  Something failed with the install - please inspect the logs above"
fi

log_running "Running Ansible to install and/or update your raspberry-noaa-v2..."
ansible-playbook -i ansible/hosts --extra-vars "@config/settings.yml" ansible/site.yml -e "target_user=$USER system_architecture=$(dpkg --print-architecture)"
if [ $? -eq 0 ]; then
  log_done "  Ansible apply complete!"
else
  die "  Something failed with the install - please inspect the logs above"
fi

# source some env vars
. "$HOME/.noaa-v2.conf"

# Allow or remove HTTP port
if [ "$ENABLE_NON_TLS" = true ]; then
  log_running "Adding HTTP firewall rule for port $WEBPANEL_PORT..."
  sudo ufw allow $WEBPANEL_PORT/tcp
else
  log_running "Removing HTTP firewall rule for port $WEBPANEL_PORT..."
  sudo ufw delete allow $WEBPANEL_PORT/tcp
fi

# Allow or remove HTTPS port
if [ "$ENABLE_TLS" = true ]; then
  log_running "Adding HTTPS firewall rule for port $WEBPANEL_TLS_PORT..."
  sudo ufw allow $WEBPANEL_TLS_PORT/tcp
else
  log_running "Removing HTTP firewall rule for port $WEBPANEL_TLS_PORT..."
  sudo ufw delete allow $WEBPANEL_TLS_PORT/tcp
fi

log_running "Installing certbot for SSL certificates signed by the Let's Encrypt..."
if [ $? -eq 0 ]; then
  sudo apt install certbot -y
else
  die "  Something failed with the install - please inspect the logs above"
fi
log_running "Configure PHP local time zone..."
if [ $? -eq 0 ]; then
   chmod +X $HOME/raspberry-noaa-v2/scripts/tools/configure_php_local_timezone.sh
   $HOME/raspberry-noaa-v2/scripts/tools/configure_php_local_timezone.sh
else
  die "  Something failed with the install - please inspect the logs above"
fi

#log_running "Installing SSL certificates..."
#if [ $? -eq 0 ] && [ $ENABLE_TLS == "true" ] && [ -n $WEB_SERVER_NAME ]; then
#  sudo certbot certonly --webroot -w /var/www/wx-new/public -d $WEB_SERVER_NAME
#  log_running "Restarting NGINX web server..."
#  sudo systemctl restart nginx
#else
#  die "  Something failed with the install - please inspect the logs above"
#fi

# TLE data files
# NOTE: This should be DRY-ed up with the scripts/schedule.sh script
WEATHER_TXT="${NOAA_HOME}/tmp/weather.txt"
AMATEUR_TXT="${NOAA_HOME}/tmp/amateur.txt"
TLE_OUTPUT="${NOAA_HOME}/tmp/orbit.tle"

# run database migrations
log_running "Updating database schema with any changes..."
$NOAA_HOME/db_migrations/update_database.sh
if [ $? -eq 0 ]; then
  log_done "  Database schema updated!"
else
  die "  Something failed with database update - please inspect the logs above"
fi

# update all web content and permissions
log_running "Updating web content..."
(
  find $WEB_HOME/ -mindepth 1 -type d -name "Config" -prune -o -print | xargs rm -rf &&
  cp -r $NOAA_HOME/webpanel/* $WEB_HOME/ &&
  sudo chown -R $USER:www-data $WEB_HOME/ &&
  sudo apt install php8.2-intl &&
  composer install -d $WEB_HOME/
) || die "  Something went wrong updating web content - please inspect the logs above"

# run a schedule of passes (as opposed to waiting until cron kicks in the evening)
log_running "Scheduling passes for imagery..."
if [ ! -f $WEATHER_TXT ] || [ ! -f $AMATEUR_TXT ] || [ ! -f $TLE_OUTPUT ]; then
  log_running "Scheduling with new TLE downloaded data..."
  ./scripts/schedule.sh -t
else
  log_running "Scheduling with existing TLE data (not downloading new)..."
  ./scripts/schedule.sh
fi
log_running "Passes scheduled!"

echo ""
echo "-------------------------------------------------------------------------------"
log_finished "CONGRATULATIONS!"
echo ""
log_finished "raspberry-noaa-v2 has been successfully installed/upgraded!"
echo ""
log_finished "You can view the webpanel updates by visiting the URL(s) listed in the"
log_finished "'output web server url' and 'output web server tls url' play outputs above."
echo "-------------------------------------------------------------------------------"
echo ""

if [ $install_type == 'install' ]; then
  log_running "It looks like this is a fresh install of the tooling for captures."
  log_running "If you've never had the software tools installed previously (e.g. if you've"
  log_running "not installed the original raspberry-noaa repo content), you likely need to"
  log_running "restart your device. Please do this to rule out any potential issues in the"
  log_running "software and libraries that have been installed."

  log_running "Automatically rebooting your device now to finish the new install."
  echo -e "\n\n\nAutomatically rebooting your device now to finish the new install."
  sudo reboot
fi
