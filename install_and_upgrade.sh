#!/bin/bash
set -e

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
log_running "Updating and installing Ansible..."
sudo apt update -yq
sudo apt install -yq ansible

if [ $? -eq 0 ]; then
  log_done "Ansible install complete!"
else
  die "Could not install Ansible - please inspect the logs"
fi

log_running "Running Ansible to install and/or update your raspberry-noaa-v2..."
ansible-playbook -i ansible/hosts ansible/site.yml

if [ $? -eq 0 ]; then
  log_done "Ansible apply complete!"
else
  die "Something failed with the install - please inspect the logs"
fi

echo ""
echo "-------------------------------------------------------------------------------"
log_finished "CONGRATULATIONS - raspberry-noaa-v2 has been successfully installed/upgraded!"
log_finished "You can view the webpanel updates by visiting http://<YOUR_IP_OR_HOSTNAME>/"
log_finished "in a web browser."
echo "-------------------------------------------------------------------------------"
