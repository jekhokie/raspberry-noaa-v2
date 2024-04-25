#!/bin/bash

# configure_php_local_timezone.sh

##################################################################################################################
# The following line is being added to index.php file so that the Web Portal passes reflect RPi local timezone
#
# Note - 
# Add -->     date_default_timezone_set('America/New_York');   or what ever the local timezone is for users RPi
##################################################################################################################
# Lets setup a local variable so we can generate the required syntax to be inserted into the index.php file

v_PHP_FILE="$HOME/raspberry-noaa-v2/webpanel/public/index.php"
local_tz=$(timedatectl | grep "Time zone" | awk -F" " '{print $3}')
insert_php_line=$(echo "date_default_timezone_set('$local_tz');")

# Check if date_default_timezone_set is configured
v_ddtzs_set=`cat ${v_PHP_FILE} | grep -i "date_default_timezone_set(" | wc -l`

if [ ${v_ddtzs_set} -eq 0 ]; then
  timestamp=$(date '+%Y-%m-%d_%H:%M:%s')
  cp -p ${v_PHP_FILE} ${v_PHP_FILE}.${timestamp}
  v_lines=`cat ${v_PHP_FILE} | wc -l`
  v_taillines=`expr ${v_lines} - 1`
  echo "<?php" > ${v_PHP_FILE}
  echo "" >> ${v_PHP_FILE}
  echo "${insert_php_line}" >> ${v_PHP_FILE}
  echo "" >> ${v_PHP_FILE} >> ${v_PHP_FILE}
  cat ${v_PHP_FILE}.${timestamp} | tail -${v_taillines} >> ${v_PHP_FILE}
  cp ${v_PHP_FILE} /var/www/wx-new/public
else
    echo "   skipping PHP local timezone is already set..."
fi
