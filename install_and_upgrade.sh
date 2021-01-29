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

# check if this is a new install or an upgrade
install_type='install'
if [ -f $HOME/.base_station.yml ]; then
  install_type='upgrade'
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
    die "  Could not install Ansible - please inspect the logs"
  fi
fi

# append pre-set variables if available
log_running "Getting any pre-configured variables..."
ansible_extra_args=""
if [ -f $HOME/.base_station.yml ]; then
  ansible_extra_args="--extra-vars \"@~/.base_station.yml\""
fi
if [ -f $HOME/.webserver.yml ]; then
  ansible_extra_args="$ansible_extra_args --extra-vars \"@~/.webserver.yml\""
fi
ansible_cmd="ansible-playbook -i ansible/hosts $ansible_extra_args ansible/site.yml"
log_running "  Done getting pre-configured variables!"

log_running "Running Ansible to install and/or update your raspberry-noaa-v2..."
eval "${ansible_cmd}"
if [ $? -eq 0 ]; then
  log_done "  Ansible apply complete!"
else
  die "  Something failed with the install - please inspect the logs"
fi

log_running "TODO: WIPE AND RE-COPY ALL WEB CONTENT"
#find $WEB_HOME/ -mindepth 1 -type d -name "images" -prune -o -type d -name "audio" -prune -o -type d -name "meteor" -prune -o -print | xargs rm -rf
#sudo cp -rp $NOAA_HOME/templates/webpanel/* $WEB_HOME/
log_running "TODO: RUN COMPOSER INSTALL IN WEB DIR"
#composer install -d $WEB_HOME/
log_running "TODO: ASSIGN RECURSIVE PERMISSIONS IN WEB DIR"
#chown -R pi:pi $WEB_HOME/

echo ""
echo "-------------------------------------------------------------------------------"
log_finished "CONGRATULATIONS!"
echo ""
log_finished "raspberry-noaa-v2 has been successfully installed/upgraded!"
log_finished "You can view the webpanel updates by visiting the following URL in a web browser:"
log_finished "http://<YOUR_IP_OR_HOSTNAME>:<CONFIGURED_PORT>/"
echo ""
log_finished "You can also see the URL listed in the 'output web server url' play output above."
echo "-------------------------------------------------------------------------------"
echo ""

if [ $install_type == 'install' ]; then
  log_running "It looks like this is a fresh install of the tooling for captures."
  log_running "If you've never had the software tools installed previously (e.g. if you've"
  log_running "not installed the original raspberry-noaa repo content), you likely need to"
  log_running "restart your device."

  log_running "TODO: PROMPT AND RESTART PI FOR ALL CONFIGS TO TAKE EFFECT ON FRESH INSTALL"
fi
