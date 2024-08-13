#!/bin/bash

# scratch_perms.sh
#
# Ensure scratch area permissions are correct after reboot

uid=${UID}
sudo chmod 755 /run/user
sudo chmod 700 /run/user/${uid}