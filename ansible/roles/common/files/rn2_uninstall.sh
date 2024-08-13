#!/bin/bash
#
# Purpose: The purpose of this uninstall script is to remove the RN2 environment 
#          and key packages like satdump, meteordemod, , predict, wxtoimg, and nginx. As well
#          as removal of RN2 crontab entries and Audio, Videos and Images in /srv
#
# Author:  Richard Creasey (AI4Y)
#
# Created: July 20th, 2024

start=$(date +%s)

UNINSTALL_LOG=/tmp/uninstall.log
PACKAGES_BULLSEYE="satdump wxtoimg nginx predict php7.4-intl php8.0-sqlite3 php8.0-mbstring php8.0-fpm"
PACKAGES_BOOKWORM="satdump wxtoimg nginx predict php8.2-intl php8.2-sqlite3 php8.2-mbstring php8.2-fpm"
PATHS="/srv/audio /srv/videos /srv/images $HOME/.config/composer $HOME/.config/gmic $HOME/.config/matplotlib $HOME/.config/meteordemod $HOME/.config/composer $HOME/.config/satdump $HOME/raspberry-noaa-v2 $HOME/.predict $HOME/.noaa-v2.conf $HOME/.wxtoimglic $HOME/.wxtoimgrc /usr/local/bin/rtl_* /var/log/raspberry-noaa-v2 /etc/sudoers.d/020_www-data-atrm-nopasswd /var/www/wx-new /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default /tmp/rtl-sdr /etc/modprobe.d/rtlsdr.conf"
SERVICES="phpsessionclean.service phpsessionclean.timer nginx.service"
OS=$(grep -E "^deb http://raspbian.raspberry.org/raspbian|^deb http://raspbian.raspberrypi.org/raspbian|^deb http://deb.debian.org/debian|^deb https://deb.debian.org/debian" /etc/apt/sources.list /etc/apt/sources.list.d/official-package-repositories.list 2> /dev/null | head -n 1 | awk '{print $3}')

if [[ ${OS} == "bookworm" ]]; then
  PACKAGES=${PACKAGES_BOOKWORM}
elif [[ ${OS} == "bullseye" ]]; then
  PACKAGES=${PACKAGES_BULLSEYE}
else
  echo "Aborting, unsupported Operating System ${OS}"
  exit 1
fi 

secs_to_human() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}

# loggit function
loggit() {
  local log_type=$1
  local log_message=$2

  echo "${log_type} : ${log_message}"

  # log output to a log file
  echo $(date '+%d-%m-%Y %H:%M') "${log_type} : ${log_message}" >> "$UNINSTALL_LOG"

}

# Check Package status
package_statuses() {

  loggit "INFO" ""
  loggit "INFO" "------------------------------"
  loggit "INFO" "Package statues"
  loggit "INFO" "------------------------------"
  for package in `echo ${PACKAGES}`;
  do
  
    PkgInstalled=$(sudo dpkg -s ${package} 2>/dev/null | grep -i "Status:" | wc -l)
  
    if [[ ${PkgInstalled} -eq 1 ]]; then
      loggit "INFO" "${package} is installed"
    else
      loggit "INFO" "${package} is NOT installed"
    fi
 
  done

  if [[ -f /usr/local/bin/meteordemod ]]; then
    loggit "INFO" "meteordemod is installed"
  else
    loggit "INFO" "meteordemod is NOT installed"
  fi
}

remove_services() {

  loggit "INFO" ""
  loggit "INFO" "------------------------------"
  loggit "INFO" "Remove RN2 Services"
  loggit "INFO" "------------------------------"
  for svc in `echo ${SERVICES}`;
  do
   
    loggit "INFO" "Stopping and removing ${svc} service"
    sudo systemctl stop ${svc}
	  # Disable causes it to remain disabled even after the service is removed and reinstalled by Ansible 
	  # this is because disable removes /etc/systemd/system/multi-user.target.wants/nginx.service and is not added back when Ansible installs it. 
	  # If Ansible had issued an systemctl enable nsinx enable it would worked. 
	  # Commenting out the disable command because disabling the service is no impact since it will be removed when removing packages 
    # sudo systemctl disable ${svc}
     
  done

}

# Remove software packages
remove_packages() {

  loggit "INFO" ""
  loggit "INFO" "------------------------------"
  loggit "INFO" "Removing packages"
  loggit "INFO" "------------------------------"
  
  for pkg in `echo ${PACKAGES}`;
  do
  
    v_result=$(sudo apt -y remove --purge ${pkg} 2>&1>/dev/null )
  
    PkgInstalled=$(sudo dpkg -s ${pkg} 2>/dev/null | grep -i "Status:" | wc -l)
 
    if [[ ${PkgInstalled} -eq 1 ]]; then
      loggit "INFO" "${pkg} is installed"
    else
      loggit "INFO" "${pkg} is no longer installed"
    fi
  
  done

  sudo rm -rf /usr/local/bin/meteordemod
  if [[ -f /usr/local/bin/meteordemod ]]; then
    loggit "INFO" "meteordemod is installed"
  else
    loggit "INFO" "meteordemod is no longer installed"
  fi
}

remove_paths() {

  loggit "INFO" ""
  loggit "INFO" "------------------------------"
  loggit "INFO" "Removing Files and Directories"
  loggit "INFO" "------------------------------"
  for path in `echo ${PATHS}`;
  do
  
    sudo rm -rf ${path}
  
    if ! (( $? )); then
      loggit "PASS" "${path} no longer exists"
    else
      loggit "FAIL" "${path} failed to remove"
    fi

  done  
}

# kill any RN2 AT processes as part of clean up, otherwise danglers 
# may have the RTL-SDR open and verification dryrun test will fail

ps aux | grep -E "receive_|satdump" | grep -v grep | awk -F" " '{print $2}' | xargs kill -9 2>/dev/null
package_statuses
remove_services
remove_packages
remove_paths

loggit "INFO" ""
loggit "INFO" "------------------------------"
loggit "INFO" "Removing RN2 CRON jobs"
loggit "INFO" "------------------------------"

crontab -l  | grep -Ev "schedule.sh|scratch_perms.sh|Ansible" > $HOME/crontab.stripped
crontab < $HOME/crontab.stripped
CronQty=$(crontab -l  | grep -Ev "schedule.sh|scratch_perms.sh|Ansible" | wc -l)

if [[ ${CronQty} -eq 0 ]]; then
  loggit "PASS" "RN2 cronjobs no longer exist"
  \rm -rf $HOME/crontab.stripped
else
  loggit "FAIL" "RN2 cronjobs were NOT removed"
fi

# Let's make sure to clean up the library cache so any dangling items are cleared
sudo ldconfig

loggit "INFO" ""
loggit "INFO" "Log of results --> ${UNINSTALL_LOG}"
echo ""

secs_to_human "$(($(date +%s) - ${start}))"
