#!/bin/bash
#
# Purpose: Output environmental information about the installed environment
#          to aid with support requests via GitHub, Discord, etc.
#
# Example:
#   ./support.sh

START_TIME=$(date '+%s')
LATEST_GIT_HASH=$(git rev-parse HEAD)
ARCH=$(uname -a)
CPUS=$(lscpu | grep "CPU(s):" | awk '{print $2}')
GIT_CHANGES=$(git diff --name-only)
SDR_INFO=$(rtl_eeprom 2>&1)

echo "============================================="
echo "Details about environment"
echo "============================================="
echo "Current date/time:  ${START_TIME}"
echo "Repo git hash:      ${LATEST_GIT_HASH}"
echo "Architecture:       ${ARCH}"
echo "Num CPUs:           ${CPUS}"

echo "---------------------------------------------"
echo "Memory Info:"
while IFS= read -r res; do
  echo "  $res"
done < <(cat /proc/meminfo | grep Mem)

echo "---------------------------------------------"
echo "Git source files changed:"
if [ -z "${GIT_CHANGES}" ]; then
  echo "  (None)"
else
  for file in $GIT_CHANGES; do
    echo "  ${file}"
  done
fi

echo "---------------------------------------------"
echo "SDR Information:"
echo -e "${SDR_INFO}"
