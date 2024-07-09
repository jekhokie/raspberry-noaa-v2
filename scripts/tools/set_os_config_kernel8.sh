#!/bin/bash

# set_os_config_kernel8.sh

###############################################################################################################################
# The following line is being added to /boot/firmware/config.txt file so that wxtoimg 32-bit app pages will align on 64-bit OS
#
# Note - 
# Add --> kernel=kernel8.img  if archeticure is aarch64 and the entry does not already exist    
###############################################################################################################################

v_CFG_FILE="/boot/firmware/config.txt"
v_cmd="/tmp/kernel_add.sh"
v_kernel8_set=`cat ${v_CFG_FILE} | grep "kernel=kernel8.img" | wc -l`

if [ ${v_kernel8_set} -eq 0 ]; then
  timestamp=$(date '+%Y-%m-%d_%H-%M-%s')
  sudo cp -p "${v_CFG_FILE}" "${v_CFG_FILE}.${timestamp}"
  echo "echo \"kernel=kernel8.img\" >> ${v_CFG_FILE}" > ${v_cmd}
  chmod +x ${v_cmd}
  sudo ${v_cmd}
  echo "...Boot firmware configured"
  rm ${v_cmd}
  echo "******* NOTICE ******* A reboot will be required for this change to take effect, so if install_and_upgrade.sh does not reboot server then you will need to"
else
    echo "...skipping setup for kernel8 configuration because it is already set..."
fi
