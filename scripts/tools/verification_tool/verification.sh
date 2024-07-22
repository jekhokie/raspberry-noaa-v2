#!/bin/bash
#
# Purpose: The purpose of this verification script is to attempt to verify the RN2 environment 
#          is installed and configured correctly. It checks permissions, file/directory ownership,
#          group permissions, package dependencies are met, key programs like satdump, meteordemod,
#          wxtoimg and wxmap are linked and execute without error during a dry run.o
#
# Author:  Richard Creasey (AI4Y)
#
# Created: July 15th, 2024

# Input parameters:
#
#   1. Input mode  [quick|full]
#
# Example:
#         ./verification.sh quick
#         ./verification.sh full

# input params
MODE=$1

echo ""
if [[ -z ${MODE} ]]; then
  echo "Argument required:  ./verification.sh quick    or    ./verification.sh full"
  echo "                        (~ 1 minute)                       (~ 5 minutes)"
  echo ""
  exit 1
else
  vMODE=$(echo ${MODE} | tr '[:lower:]' '[:upper:]')
  if [[ ${vMODE} != "QUICK" && ${vMODE} != "FULL" ]]; then
    echo "Argument required:  ./verification.sh quick    or    ./verification.sh full"
    echo "                        (~ 1 minute)                       (~ 5 minutes)"
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
    echo "Time Elapsed : ${min} minutes and ${secs} seconds."
}

LANG=POSIX
VALIDATION_LOG=/var/log/raspberry-noaa-v2/verification.log
PERMISSIONS_LIST=/home/$USER/raspberry-noaa-v2/scripts/tools/verification_tool/config/permissions.list
PERMISSIONS_ARM64_LIST=/home/$USER/raspberry-noaa-v2/scripts/tools/verification_tool/config/permissions_arm64.list
PERMISSIONS_OTHER_LIST=/home/$USER/raspberry-noaa-v2/scripts/tools/verification_tool/config/permissions_other.list
PACKAGE_LIST=/home/$USER/raspberry-noaa-v2/scripts/tools/verification_tool/config/package.list
PACKAGE_ARM64_LIST=/home/$USER/raspberry-noaa-v2/scripts/tools/verification_tool/config/package_arm64.list
TEST_FILES=$HOME/raspberry-noaa-v2/scripts/tools/verification_tool/test_files
mkdir -p -m 755 ${TEST_FILES}/tmp
declare -A levels=([PASS]=1 [FAIL]=2 [INFO]=3)
log_level=${LOG_LEVEL}
FAILURES=0
PASSES=0
echo "" > $VALIDATION_LOG

TEST_LOG=/tmp/verficiation_test.log
PIP_LOG=/tmp/pip_installed.log
ARCH=$(dpkg --print-architecture)
BIN_SCRIPT=/tmp/verficiation_test.sh
LDD=$(which ldd)

if [[ ${ARCH} == "arm64" ]]; then
  LDD=$(which ldd)
  LDD32=/tmp/ldd32
  cat ${LDD} | sed -e 's/ld-linux-aarch64.so.1/ld-linux-armhf.so.3/' > ${LDD32}
  chmod +x ${LDD32}
fi

# loggit function
loggit() {
  local log_type=$1
  local log_message=$2

  echo "${log_type} : ${log_message}"

  # log output to a log file
  echo $(date '+%d-%m-%Y %H:%M') "${log_type} : ${log_message}" >> "$VALIDATION_LOG"

}


# The function will test and report
perms() {

  localuser=$USER

  ptype=$1
  #echo "ptype=${ptype}"
  if [[ "${ptype}" == "file" ]]; then
    ptype="regular file"
  elif [[ "${ptype}" == "symbolic" ]]; then 
    ptype="symbolic link"
  fi

  rperms=$2
  owner=$3
  #echo "owner=${owner}"
  if [[ "${owner}" == "\$USER" ]]; then
    #echo "Setting owner, current owner=${owner}, USER=${USER}, localuser=${localuser}"
    owner=$localuser
  #  echo "owner=${owner}"
  fi

  group=$4
  #echo "group=${group}"
  if [[ "${group}" == "\$USER" ]]; then
    group=$localuser
  #  echo "group=${group}"
  fi

  path=$5
  #echo "path=${path}"
  if [[ "${path}" == *"\$USER"* ]]; then
    path=$(echo ${path} | sed  -e "s/\$USER/${localuser}/g")
  #  echo "path=${path}"
  fi
  
  #echo "-----------------"
  #echo "ptype=${ptype}"
  #echo "rperms=${rperms}"
  #echo "owner=${owner}"
  #echo "group=${group}"
  #echo "path=${path}"
  #echo "-----------------"

  if [[ -e $path ]]; then
    status=$(stat -c "%F %a %U %G %n" ${path})
    if [[ "${status}" == "${ptype} ${rperms} ${owner} ${group} ${path}" ]]; then
      loggit "PASS" "${status}"
      PASSES=$(expr ${PASSES} + 1)
    else
      loggit "FAIL" "****************************************************"
      loggit "FAIL" "CURRENT ${status}"
      loggit "FAIL" "DESIRED ${ptype} ${rperms} ${owner} ${group} ${path}"
      loggit "FAIL" "****************************************************"
      FAILURES=$(expr ${FAILURES} + 1)
    fi
  else
    loggit "FAIL" "$path does not exist"
    FAILURES=$(expr ${FAILURES} + 1)
  fi


}

# run as a normal user for any scripts within
if [ $EUID -eq 0 ]; then
  log "This script shouldn't be run as root." "ERROR"
  exit 1
fi

# There is a chance that this verification script is being executed after a fresh install of OS/RN2, so execute dryrun of satdump to precreate satdump configuration directories/files
CMD="/usr/bin/satdump live noaa_apt . --source rtlsdr --samplerate 1.024e6 --frequency 137.9125e6 --satellite_number 18 --fill_missing --sdrpp_noise_reduction --gain 49.6 --timeout 1"
echo ${CMD} > ${BIN_SCRIPT};chmod +x ${BIN_SCRIPT}
${BIN_SCRIPT} > ${TEST_LOG} 2>&1

loggit "INFO" ""
loggit "INFO" ""
loggit "INFO" ""
loggit "INFO" "************** Starting Validation **************"
loggit "INFO" ""
loggit "INFO" "*************************************************"
loggit "INFO" "*** Checking Ownership and Permissions ***"
loggit "INFO" "*************************************************"

while IFS= read -r line; do
  perms ${line}
done < ${PERMISSIONS_LIST}

if [[ ${ARCH} == "arm64" ]]; then
  while IFS= read -r line; do
    perms ${line}
  done < ${PERMISSIONS_ARM64_LIST}
fi

while IFS= read -r line; do
  perms ${line}
done < ${PERMISSIONS_OTHER_LIST}

loggit "INFO" ""
loggit "INFO" "*************************************************"
loggit "INFO" "*** Checking required packages ***"
loggit "INFO" "*************************************************"

while IFS= read -r line; do
  package_status=$(dpkg-query -W ${line} | head -1)
  if [[ "${package_status}" == *"no packages found matching"* ]]; then
    loggit "FAIL" "${package_status}"
    FAILURES=$(expr ${FAILURES} + 1)
  else
    loggit "PASS" "${package_status}"
    PASSES=$(expr ${PASSES} + 1)
  fi
done < ${PACKAGE_LIST}

if [[ ${ARCH} == "arm64" ]]; then
  while IFS= read -r line; do
    package_status=$(dpkg-query -W ${line} | head -1)
    if [[ "${package_status}" == *"no packages found matching"* ]]; then
      loggit "FAIL" "${package_status}"
      FAILURES=$(expr ${FAILURES} + 1)
    else
      loggit "PASS" "${package_status}"
      PASSES=$(expr ${PASSES} + 1)
    fi
  done < ${PACKAGE_ARM64_LIST}
fi

loggit "INFO" ""
loggit "INFO" "*************************************************"
loggit "INFO" "*** Checking required PIP packages ***"
loggit "INFO" "*************************************************"

pip list > ${PIP_LOG}
for pip_package in envbash facebook pysqlite;
do 
  v_result=$(cat ${PIP_LOG} | grep ${pip_package});
  if [[ ${v_result} ]]; then
    loggit "PASS" "${v_result}"
    PASSES=$(expr ${PASSES} + 1)
  else
    loggit "FAIL" "Python package ${pip_package} is not installed"
    FAILURES=$(expr ${FAILURES} + 1)
  fi
done

loggit "INFO" ""
loggit "INFO" "*************************************************"
loggit "INFO" "*** Checking RN2 crontab jobs ***"
loggit "INFO" "*************************************************"

cronjob1="1 0 * * * /home/richard/raspberry-noaa-v2/scripts/schedule.sh -t"
cronjob2="@reboot /home/richard/raspberry-noaa-v2/scripts/schedule.sh"
cronjob3="@reboot /home/richard/raspberry-noaa-v2/scripts/tools/scratch_perms.sh"
cron1=$(crontab -l | grep -v "^#" | grep -F "${cronjob1}" | wc -l)
cron2=$(crontab -l | grep -v "^#" | grep -F "${cronjob2}" | wc -l)
cron3=$(crontab -l | grep -v "^#" | grep -F "${cronjob3}" | wc -l)
crontotal=`expr ${cron1} + ${cron2} + ${cron3}`

if [[ ${crontotal} -eq 3 ]]; then
  loggit "PASS" "All RN2 enabled crontab jobs found"
else
  loggit "FAIL" "All RN2 enabled crontab jobs NOT found"
fi

loggit "INFO" ""
loggit "INFO" "*************************************************"
loggit "INFO" "*** Perform Dryrun Binary Tests ***"
loggit "INFO" "*************************************************"

###############################
# Dryrun Binary Test Commands #
###############################

NGINX="/usr/sbin/nginx"
NGINX_CMD="curl -s --head --request GET http://0.0.0.0/passes | grep '200 OK'"

SATDUMP="/usr/bin/satdump"
SATDUMP_CMD="${SATDUMP} live noaa_apt . --source rtlsdr --samplerate 1.024e6 --frequency 137.9125e6 --satellite_number 18 --fill_missing --sdrpp_noise_reduction --gain 49.6 --timeout 1"

METEORDEMOD="/usr/local/bin/meteordemod"
METEORDEMOD_QCMD="${METEORDEMOD} -h"
METEORDEMOD_CMD="${METEORDEMOD} -m oqpsk -diff 1 -s 72000 -sat 'METEOR-M-2-3' -t '${TEST_FILES}/meteordemod-input.tle' -f jpg -i '${TEST_FILES}/meteordemod-input.cadu' -o '${TEST_FILES}/tmp'"

WXMAP="/usr/local/bin/wxmap"
WXMAP_CMD="${WXMAP} -T 'NOAA 15' -H '${TEST_FILES}/wxtoimg-input.tle' -p 0  -l 1 -c l:0xcc3030 -g 10.0 -c g:0xff0000 -C 1 -c C:0xffff00 -S 1 -c S:0xffff00 -o '1721222580' '${TEST_FILES}/wxtoimg-map-output.png' 2>&1 | grep -Ev 'invalid pointer|Aborted'"

WXTOIMG="/usr/local/bin/wxtoimg"
WXTOIMG_CMD="${WXTOIMG} -o -m ${TEST_FILES}/wxtoimg-map-input.png  -c -I -e MCIR ${TEST_FILES}/wxtoimg-input.wav ${TEST_FILES}/wxtoimg-mcir-output.jpg 2>&1 | grep -Ev 'invalid pointer|Aborted'"

for BIN in ${NGINX} ${SATDUMP} ${WXMAP} ${WXTOIMG} ${METEORDEMOD} ;
do 
  BINNAME=$(echo ${BIN} | awk -F"/" '{print $NF}' | tr '[:lower:]' '[:upper:]')
  BINCMD="${BINNAME}_CMD"

  if [[ ${ARCH} == "arm64" && ${BINNAME} == "WXTOIMG" || ${ARCH} == "arm64" && ${BINNAME} == "WXMAP" ]]; then
    # We are on ARM64 with 32-bit executables, so we must use the modified ldd script to ensure proper results when checking libraries link
    v_lddresult=$(${LDD32} ${BIN} | grep -i "not found" | wc -l)
  else
    v_lddresult=$(${LDD} ${BIN} | grep -i "not found" | wc -l)
  fi

  if [[ ${v_lddresult} -eq 0 ]]; then
    loggit "PASS" "${BIN} has all required libraries"
    PASSES=$(expr ${PASSES} + 1)

    # Perform Dry run execution since all libraries are dynamiclly linked
    #
    # Writing test command to a file to call for execution. SATDUMP and METEORDEMOD could be called 
    # directly from varible, but WXMAP and WXTOIMG arguments would not pass correctly 
    echo ${!BINCMD} > ${BIN_SCRIPT};chmod +x ${BIN_SCRIPT}
    if [[ ${BINNAME} == 'METEORDEMOD' && ${vMODE} == "FULL" ]]; then
      loggit "INFO" "*** FULL mode choosen *** - Please wait for meteordemod testing to complete... ~ 4 minutes"
      ${BIN_SCRIPT} >> ${TEST_LOG} 2>&1
      vResult=$?
      if (( ${vResult} )); then
        vError=$(cat ${TEST_LOG} | tail -1)
        loggit "FAIL" "${BIN} dry run failed: ${vError}"
        FAILURES=$(expr ${FAILURES} + 1)
      else
        loggit "PASS" "${BIN} dry run was successful"
        PASSES=$(expr ${PASSES} + 1)
      fi
    elif [[ ${BINNAME} != 'METEORDEMOD' ]]; then
      ${BIN_SCRIPT} >> ${TEST_LOG} 2>&1
      vResult=$?
      if (( ${vResult} )); then
        vError=$(cat ${TEST_LOG} | tail -1)
        loggit "FAIL" "${BIN} dry run failed: ${vError}"
        FAILURES=$(expr ${FAILURES} + 1)
      else
        loggit "PASS" "${BIN} dry run was successful"
        PASSES=$(expr ${PASSES} + 1)
      fi
    elif [[ ${BINNAME} == 'METEORDEMOD' ]]; then
      BINCMD="${BINNAME}_QCMD"
      echo ${!BINCMD} > ${BIN_SCRIPT};chmod +x ${BIN_SCRIPT}
      ${BIN_SCRIPT} >> ${TEST_LOG} 2>&1
      vResult=$?
      if (( ${vResult} )); then
        vError=$(cat ${TEST_LOG} | tail -1)
        loggit "FAIL" "${BIN} dry run failed: ${vError}"
        FAILURES=$(expr ${FAILURES} + 1)
      else
        loggit "PASS" "${BIN} dry run was successful"
        PASSES=$(expr ${PASSES} + 1)
      fi
    fi
  else
    loggit "FAIL" "${BIN} is missing ${v_lddresult} required librarie(s)"
    FAILURES=$(expr ${FAILURES} + 1)
    loggit "FAIL" "${BIN} skipping dry run execution due to missing librarie(s)"
    FAILURES=$(expr ${FAILURES} + 1)    
  fi

done

loggit "INFO" ""
loggit "INFO" "===================================================="
loggit "INFO" "Passing tests ${PASSES}    Failing tests ${FAILURES}"
loggit "INFO" "===================================================="
loggit "INFO" ""
loggit "INFO" "Log of results --> ${VALIDATION_LOG}"
loggit "INFO" ""
loggit "INFO" "************** Ending Validation ****************"

##################################################
# Clean up temporary files used during execution #
##################################################

if [[ ${ARCH} == "arm64" ]]; then
  if [[ -f ${LDD32} ]]; then
    \rm ${LDD32}
  fi 
fi

if [[ -f  ${BIN_SCRIPT} ]]; then
  \rm -f ${BIN_SCRIPT} ${PIP_LOG} raw_*.png product.cbor dataset.json APT-*.png ${TEST_FILES}/tmp/*.bmp ${TEST_FILES}/tmp/*.dat 2>/dev/null
fi

secs_to_human "$(($(date +%s) - ${start}))"
