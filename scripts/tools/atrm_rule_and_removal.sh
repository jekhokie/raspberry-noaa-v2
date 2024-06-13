#!/bin/bash

# atrm_rule_and_removal.sh
#
# Modify the sudo rule file, which will keep the required tight restrictions to just the atrm command, but allow www-data to sudo as the user that created the AT job to run that command.

# configure sudo rule and AdminController.php to remove scheduled job from user used to schedule it

v_atrm_file="$HOME/raspberry-noaa-v2/ansible/roles/webserver/files/020_www-data-atrm-nopasswd"
#v_atrm_cmd="www-data ALL=(ALL) NOPASSWD: /usr/bin/sudo -u $USER /usr/bin/atrm"
v_atrm_cmd="www-data ALL=(ALL) NOPASSWD: /usr/bin/atrm"

v_ctl_app="$HOME/raspberry-noaa-v2/webpanel/App/Controllers/AdminController.php"
v_ctl_cmd="echo shell_exec(\"sudo -u $USER /usr/bin/atrm \" . \$pass->at_job_id . \" 2>&1\");"

# Check if the correct rule file is configured
v_atrmrule_set=`cat ${v_atrm_file} | grep -i "${v_atrm_cmd}" | wc -l`

if [ ${v_atrmrule_set} -eq 0 ]; then
  echo "   Modifying sudo ATRM Rule..."
  timestamp=$(date '+%Y-%m-%d_%H:%M:%s')
  cp -p ${v_atrm_file} ${v_atrm_file}.${timestamp}
  echo "${v_atrm_cmd}" > ${v_atrm_file}
else
  echo "   skipping, ATRM Rule is already set..."
fi

# Check if AdminController.php ATRM command is configured
v_atrmctlcmd_set=`cat ${v_ctl_app} | grep 'USER atrm \" . $pass->at_job_id' | wc -l`

if [ ${v_atrmctlcmd_set} -eq 1 ]; then
  echo "   Modifying ATRM command in AdminController..."
  timestamp=$(date '+%Y-%m-%d_%H:%M:%s')
  cp -p ${v_ctl_app} ${v_ctl_app}.${timestamp}
  v_omit_line=$(cat ${v_ctl_app} | grep -n -m 1 'USER atrm \" . $pass->at_job_id' | awk -F":" '{print $1}')
  v_head_stop=$(expr ${v_omit_line} - 1)
  v_lines=$(cat ${v_ctl_app} | wc -l)
  v_tail_start=$(expr ${v_lines} - ${v_omit_line})
  cat ${v_ctl_app} | head -${v_head_stop} > ${v_ctl_app}.new
  echo "        ${v_ctl_cmd}" >> ${v_ctl_app}.new
  cat ${v_ctl_app} | tail -${v_tail_start} >> ${v_ctl_app}.new
  mv ${v_ctl_app}.new ${v_ctl_app}
else
  echo "   skipping, AdminController.php : sudo $USER ATRM is already set..."
fi
