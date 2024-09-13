#!/bin/bash
#
# Purpose: Upgrade an existing RN2 installation in situ while retaining key files
#
#          Process Flow:
#
#          1) Backup/Stage RN2 key directories 
#          
#          2) Uninstall existing RN2 installation
#
#          3) git clone new repository
#
#          4) Restore/UnStage RN2 key directories 
#
#          5) install_and_upgrade 
#
#          6) verification tool
#
#
# Author:  Richard Creasey (AI4Y)
#
# Created: 28-July-2024
#
#
# Input parameter:
#
#   1. Input Repo URL / branch name
#
#       ./rn2_upgrade.sh  "https://github.com/jekhokie/raspberry-noaa-v2.git -b aarch64-support"
#

ACNT=$#
REPO=$1
BARG=$2
BRANCH=$3

echo ""
if [[ -z ${REPO} ]]; then
  echo "Argument required:  ./rn2_upgrade.sh  https://github.com/jekhokie/raspberry-noaa-v2.git -b aarch64-support"
  echo ""
  exit 1
fi

if [[ ${ACNT} -gt 1 ]]; then

  if [[ ${BARG} != "-b" ]]; then
    echo "2nd Argument must be -b"
    echo ""
    echo "                 ./rn2_upgrade.sh  https://github.com/jekhokie/raspberry-noaa-v2.git -b aarch64-support"
    echo ""
    exit 1
  fi

  if [[ -z ${BRANCH} ]]; then
    echo "3rd Argument branch-name required:"
    echo ""
    echo "                ./rn2_upgrade.sh  https://github.com/jekhokie/raspberry-noaa-v2.git -b aarch64-support"
    echo ""
    exit 1
  fi
  
fi

start=$(date +%s)

secs_to_human() {
    if [[ -z ${1} || ${1} -lt 60 ]] ;then
        min=0 ; secs="${1}"
    else
        time_mins=$(echo "scale=2; ${1}/60" | bc)
        min=$(echo ${time_mins} | cut -d'.' -f1)
        secs="0.$(echo ${time_mins} | cut -d'.' -f2)"
        secs=$(echo ${secs}*60|bc|awk '{print int($1+0.5)}')
    fi
    echo "RN2 Upgrade Time Elapsed : ${min} minutes and ${secs} seconds."
}

# Define RN2 Utils location
RN2_UTILS="${HOME}/.rn2_utils"

# Define log file for backup/restore activity
LOG="${RN2_UTILS}/rn2_upgrade.log"

{

echo "##########################################################################"
echo "# Testing git clone arguments passed before destructive tasks are performed"
echo "##########################################################################"
cd /tmp
echo "git clone --depth 1 ${REPO}  ${BARG}  ${BRANCH}"
git clone --depth 1 ${REPO} ${BARG} ${BRANCH}

if [[ $? != 0 ]]; then
  echo "FAILED to git clone repo/branch passed, please check and try again"
  exit 1
fi

echo "###################################################################"
echo "# Check existing settings.yml meets requirements for new repository"
echo "###################################################################"

python3 /tmp/raspberry-noaa-v2/scripts/tools/validate_yaml.py ${HOME}/raspberry-noaa-v2/config/settings.yml /tmp/raspberry-noaa-v2/config/settings_schema.json
v_result=$?

if [[ ${v_result} -ne 0 ]]; then
  cp -p /tmp/raspberry-noaa-v2/config/settings.yml /tmp/settings.yml
  echo ""
  echo "Your existing ${HOME}/raspberry-noaa-v2/config/settings.yml is missing one or more new parameters, which are required by the repository you are trying to upgraded to."
  echo ""
  echo "Please see the above \"required property\"'s reported and add to your settings.yml before trying to upgrade again."
  echo ""
  echo "Please look at /tmp/settings.yml for example of the missing parameter"
  \rm -rf /tmp/raspberry-noaa-v2
  exit 1
fi

echo "#####################################################"
echo "# Perform RN2 Key file backup/stage"
echo "#####################################################"
${RN2_UTILS}/rn2_backup_restore.sh backup_stage

echo "#####################################################"
echo "# Uninstall existing RN2 installation"
echo "#####################################################"
${RN2_UTILS}/rn2_uninstall.sh

echo "#####################################################"
echo "# Swap in git cloned repository into users home"
echo "#####################################################"
cd ${HOME}
mv /tmp/raspberry-noaa-v2 ${HOME}

if [[ $? == 0 ]]; then
  echo "Succcessfully moved RN2 tree from /tmp to home directory"
else
  echo "FAILED to move RN2 tree from /tmp to home directory, aborting..."
  exit 1
fi

echo "#####################################################"
echo "# Restore/UnStage RN2 key directories"
echo "#####################################################"
${RN2_UTILS}/rn2_backup_restore.sh restore_stage

echo "#####################################################"
echo "# Execute install_and_upgrade"
echo "#####################################################"
cd ${HOME}/raspberry-noaa-v2
./install_and_upgrade.sh

# Determine if verification tool was in the repo cloned 
if [[ -f ${HOME}/raspberry-noaa-v2/scripts/tools/verification_tool/verification.sh ]]; then
  # Confirm if install_and_upgrade.sh script code already executed it or not
  vFound=$(cat ${HOME}/raspberry-noaa-v2/install_and_upgrade.sh | grep verification.sh | wc -l)
  if [[ ${vFound} -eq 0 ]]; then
    echo "#####################################################"
    echo "# Execute Verification Tool"
    echo "#####################################################"
    ${HOME}/raspberry-noaa-v2/scripts/tools/verification_tool/verification.sh quick
  fi
else
  echo "The installed GitHub REPO has not been updated with the Verification Tool, skipping..."
fi

secs_to_human "$(($(date +%s) - ${start}))"
} | tee -a ${LOG}
