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
PACKAGES="satdump wxtoimg nginx predict"
PATHS="/srv/audio /srv/videos /srv/images $HOME/.config/composer $HOME/.config/gmic $HOME/.config/matplotlib $HOME/.config/meteordemod $HOME/.config/composer $HOME/.config/satdump $HOME/raspberry-noaa-v2 $HOME/.predict $HOME/.noaa-v2.conf $HOME/.wxtoimglic $HOME/.wxtoimgrc /usr/local/bin/rtl_* /var/log/raspberry-noaa-v2" 

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

# Remove software packages
remove_packages() {

  loggit "INFO" ""
  loggit "INFO" "------------------------------"
  loggit "INFO" "Removing packages"
  loggit "INFO" "------------------------------"
  
  sudo systemctl stop nginx
  sudo systemctl stop php-fpm
  for pkg in `echo ${PACKAGES}`;
  do
  
    v_result=$(sudo apt -y remove --purge ${pkg} 2>&1>/dev/null )
  
    PkgInstalled=$(sudo dpkg -s ${pkg} 2>/dev/null | grep -i "Status:" | wc -l)
 
    if [[ ${PkgInstalled} -eq 1 ]]; then
      loggit "INFO" "${pkg} is installed"
    else
      loggit "INFO" "${pkg} is NOT installed"
    fi
  
  done

  sudo rm -rf /usr/local/bin/meteordemod
  if [[ -f /usr/local/bin/meteordemod ]]; then
    loggit "INFO" "meteordemod is installed"
  else
    loggit "INFO" "meteordemod is NOT installed"
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

package_statuses
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
  loggit "PASS" "RN2 cronjobs are removed"
  \rm -rf $HOME/crontab.stripped
else
  loggit "FAIL" "RN2 cronjobs are NOT removed"
fi


loggit "INFO" ""
loggit "INFO" "Log of results --> ${UNINSTALL_LOG}"
echo ""

secs_to_human "$(($(date +%s) - ${start}))"