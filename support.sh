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
RPI_MODEL=$(cat /proc/device-tree/model | tr -d '\0')
DISK_LAYOUT=$(lsblk)
DB_TABLES=$(sqlite3 db/panel.db "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")

echo "============================================="
echo "Details about environment"
echo "============================================="
echo "Current local date/time: $(date -d @$START_TIME)"
echo "Current date/time (ms):  ${START_TIME}"
echo "Repo git hash:           ${LATEST_GIT_HASH}"
echo "Raspberry Pi Model:      ${RPI_MODEL}"
echo "Architecture:            ${ARCH}"
echo "Num CPUs:                ${CPUS}"

echo "---------------------------------------------"
echo "'at' Scheduled Jobs (Captures):"

# get the at jobs
atq_jobs=()
while IFS= read -r res; do
  atq_jobs+=("${res}")
done < <(atq)

# parse and save the job information
AT_COMMANDS=()
for job in "${atq_jobs[@]}"; do
  job_id=$(echo "${job}" | awk '{print $1}')
  cmd=$(at -c $job_id | grep -e "receive_meteor.sh" -e "receive_noaa.sh")
  AT_COMMANDS+=("[${job}] -> ${cmd}")
done

# output the job details (if any available)
if [ "${#AT_COMMANDS[@]}" == "0" ]; then
  echo "  (None)"
else
  for cmd in "${AT_COMMANDS[@]}"; do
    echo "  * ${cmd}"
  done
fi

echo "---------------------------------------------"
echo "Satellite SDR Settings:"
while IFS= read -r res; do
  echo "  $res"
done < <(grep -E 'noaa_(15|18|19)_|meteor_m2_' config/settings.yml)

echo "---------------------------------------------"
echo "USB Device Map:"
while IFS= read -r res; do
  echo "  $res"
done < <(lsusb)

echo "---------------------------------------------"
echo "Disk Info:"
while IFS= read -r res; do
  echo "  $res"
done < <(lsblk)

echo "---------------------------------------------"
echo "Disk Usage Info:"
while IFS= read -r res; do
  echo "  $res"
done < <(df)

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

echo "---------------------------------------------"
echo "Database tables:"
if [ -z "${DB_TABLES}" ]; then
  echo "  (None)"
else
  for db_table in $DB_TABLES; do
    table_schema=$(sqlite3 db/panel.db ".schema ${db_table}")
    echo "  ${db_table} =>"
    echo "      ${table_schema}"
    echo ""
  done
fi
