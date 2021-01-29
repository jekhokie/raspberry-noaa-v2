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
  die "Please run this script as the pi user (not as root)"
fi

# verify the repo exists as expected in the home directory
if [ ! -e "$HOME/raspberry-noaa-v2" ]; then
  die "Please clone https://github.com/jekhokie/raspberry-noaa-v2 to your home directory"
fi

# install ansible
which ansible
if [ $? -ne 0 ]; then
  log_running "Updating and installing Ansible..."
  sudo apt update -yq
  sudo apt install -yq ansible

  if [ $? -eq 0 ]; then
    log_done "Ansible install complete!"
  else
    die "Could not install Ansible - please inspect the logs"
  fi
fi

log_running "Running Ansible to install and/or update your raspberry-noaa-v2..."
if [ -f "$HOME/.base_station.yml" ]; then
  log_running "  Found existing config parameters - using them!"
  ansible-playbook -i ansible/hosts ansible/site.yml --extra-vars "@$HOME/.base_station.yml"
else
  log_running "  Brand new install - going to prompt for user input"
  ansible-playbook -i ansible/hosts ansible/site.yml
fi

if [ $? -eq 0 ]; then
  log_done "Ansible apply complete!"
else
  die "Something failed with the install - please inspect the logs"
fi

log_running "TODO: WIPE AND RE-COPY ALL WEB CONTENT"
#find $WEB_HOME/ -mindepth 1 -type d -name "images" -prune -o -type d -name "audio" -prune -o -type d -name "meteor" -prune -o -print | xargs rm -rf
#sudo cp -rp $NOAA_HOME/templates/webpanel/* $WEB_HOME/
log_running "TODO: RUN COMPOSER INSTALL IN WEB DIR"
#composer install -d $WEB_HOME/
log_running "ASSIGN RECURSIVE PERMISSIONS IN WEB DIR"
#chown -R pi:pi $WEB_HOME/

echo ""
echo "-------------------------------------------------------------------------------"
log_finished "CONGRATULATIONS - raspberry-noaa-v2 has been successfully installed/upgraded!"
log_finished "You can view the webpanel updates by visiting the following URL in a web browser:"
log_finished "http://<YOUR_IP_OR_HOSTNAME>:<CONFIGURED_PORT>/"
echo "-------------------------------------------------------------------------------"
