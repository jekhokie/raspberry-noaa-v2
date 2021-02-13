#!/bin/bash

echo "Disabling WiFi power mgmt..."
iwconfig wlan0 power off
if [ $? -eq 0 ]; then
  echo "WiFi power mgmt successfully disabled!"
else
  echo "Error attempting to disable WiFi power mgmt!"
fi
