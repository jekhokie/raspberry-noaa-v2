#!/bin/bash
#
# Purpose: Backup or Restore RN2 key directories 
#          
#          (audio, videos, images, db and config)
#
# Author:  Richard Creasey (AI4Y)
#
# Created: 28-July-2024
#
#
# Input parameters:
#
#   1. Input mode  [backup|backup_stage|restore|restore_stage]
#
# Example:
#         ./rn2_backup_restore.sh backup
#         ./rn2_backup_restore.sh backup_stage
#         ./rn2_backup_restore.sh restore
#         ./rn2_backup_restore.sh restore_stage

# input params
MODE=$1

echo ""
if [[ -z ${MODE} ]]; then
  echo "Argument required:  ./rn2_backup_restore.sh backup    or    ./rn2_backup_restore.sh backup_stage"
  echo "                    ./rn2_backup_restore.sh restore   or    ./rn2_backup_restore.sh restore_stage"
  echo ""
  exit 1
else
  vMODE=$(echo ${MODE} | tr '[:upper:]' '[:lower:]')
  if [[ ${vMODE} != "backup" && ${vMODE} != "backup_stage" && ${vMODE} != "restore" && ${vMODE} != "restore_stage" ]]; then
    echo "Argument required:  ./rn2_backup_restore.sh backup    or    ./rn2_backup_restore.sh backup_stage"
    echo "                    ./rn2_backup_restore.sh restore   or    ./rn2_backup_restore.sh restore_stage"
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

# Define RN2 Utils location
RN2_UTILS="${HOME}/.rn2_utils"

# Define backup location
BACKUP_LOC="${RN2_UTILS}/backup"

# Make sure backup location exists
mkdir -p ${BACKUP_LOC} ${BACKUP_LOC}/srv

# Define log file for backup/restore activity
LOG="${BACKUP_LOC}/backup_restore.log"

# loggit function
loggit() {
  local log_type=$1
  local log_message=$2

  echo "${log_type} : ${log_message}"

  # log output to a log file
  echo $(date '+%d-%m-%Y %H:%M') "${log_type} : ${log_message}" >> "$LOG"
}

backup() {

  if [[ ${stage} -eq 0 ]]; then
    # Making a full copy of /srv/audio, /srv/videos, /srv/ images

    if [[ -d /srv ]]; then

      srcSIZE=$(du -sm /srv | awk -F" " '{print $1}')
      FreeSpace=$(df -m ${BACKUP_LOC} | grep -vi "Filesystem" | awk -F" " '{print $(NF-2)}')

      # To ensure stability of the OS and processes, lets make sure we have at least 2GB of free space beyond the minimun needed before making a backup
      RequiredSpace=$((${srcSIZE} + 2000))

      if [[ ${RequiredSpace} -lt ${FreeSpace} ]]; then
        loggit "INFO" "Required space for backup is ${RequiredSpace} MB and Free space is ${FreeSpace} MB, preceeding to backup RN2 key files..."

        loggit "INFO" "Backing up /srv/audio, please wait..."
        cp -pr /srv/audio ${BACKUP_LOC}/srv/audio
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully backed up /srv/audio"
        else
          loggit "FAIL" "Failed to backup /srv/audio, aborting..."
          exit 1
        fi

        loggit "INFO" "Backing up /srv/videos, please wait..."
        cp -pr /srv/videos ${BACKUP_LOC}/srv/videos
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully backed up /srv/videos"
        else
          loggit "FAIL" "Failed to backup /srv/videos, aborting..."
          exit 1
        fi

        loggit "INFO" "Backing up /srv/images, please wait..."
        cp -pr /srv/images ${BACKUP_LOC}/srv/images
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully backed up /srv/images"
        else
          loggit "FAIL" "Failed to backup /srv/images, aborting..."
          exit 1
        fi

      else
        loggit "FAIL" "Required space for backup is ${RequiredSpace} MB and Free space is only ${FreeSpace} MB, aborting..."
        exit 1
      fi

    else

      loggit "INFO" "/srv directory not found, skipping backup..."

    fi

  else 

    # Staging /srv so no extra space or time is required
    if [[ ! -d /srv_staged ]]; then
      loggit "INFO" "Staging /srv as /srv_staged"
      sudo mv /srv /srv_staged
    else
      loggit "FAIL" "/srv_staged already exists, aborting..."
      exit 1
    fi

  fi


  if [[ -f ${HOME}/raspberry-noaa-v2/config/settings.yml ]]; then
    cp -pr ${HOME}/raspberry-noaa-v2/config/settings.yml ${BACKUP_LOC}/settings.yml
    if [[ $? -eq 0 ]]; then
      loggit "PASS" "Successfully backed up settings.yml"
    else
      loggit "FAIL" "Failed to backup settings.yml, aborting..."
      exit 1
    fi
  else
    loggit "FAIL" "${HOME}/raspberry-noaa-v2/config/settings.yml not found, aborting..."
    exit
  fi

  if [[ -f ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2 ]]; then
    cp -pr ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2 ${BACKUP_LOC}/annotation.html.j2
    if [[ $? -eq 0 ]]; then
      loggit "PASS" "Successfully backed up annotation.html.j2"
    else
      loggit "FAIL" "Failed to backup annotation.html.j2, aborting..."
      exit 1
    fi
  else
    loggit "FAIL" "${HOME}/raspberry-noaa-v2/config/settings.yml, not found, aborting..."
    exit
  fi

  if [[ -f ${HOME}/raspberry-noaa-v2/db/panel.db ]]; then
    cp -pr ${HOME}/raspberry-noaa-v2/db/panel.db ${BACKUP_LOC}/panel.db
    if [[ $? -eq 0 ]]; then
      loggit "PASS" "Successfully backed up panel.db"
    else
      loggit "FAIL" "Failed to backup panel.db, aborting..."
      exit 1
    fi
  else
    loggit "FAIL" "${HOME}/raspberry-noaa-v2/db/panel.db, not found, aborting..."
    exit
  fi

}

restore() {


  if [[ ${stage} -eq 0 ]]; then
    # Restoring a full copy of /srv/audio, /srv/videos, /srv/ images

    if [[ -d ${BACKUP_LOC}/srv ]]; then
      srcSIZE=$(du -sm ${BACKUP_LOC} | awk -F" " '{print $1}')
      FreeSpace=$(df -m /srv | grep -vi "Filesystem" | awk -F" " '{print $(NF-2)}')

      # To ensure stability of the OS and processes, lets make sure we have at least 2GB of free space beyond the minimun needed before restoring
      RequiredSpace=$((${srcSIZE} + 2000))

      if [[ ${RequiredSpace} -lt ${FreeSpace} ]]; then
        loggit "INFO" "Required space for restore is ${RequiredSpace} MB and Free space is ${FreeSpace} MB, preceeding to restore RN2 key files..."

        loggit "INFO" "Restoring /srv/audio, please wait..."
        cp -pr ${BACKUP_LOC}/srv/audio /srv/audio
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully restored /srv/audio"
        else
          loggit "FAIL" "Failed to restore /srv/audio, aborting..."
          exit 1
        fi

        loggit "INFO" "Restoring /srv/videos, please wait..."
        cp -pr ${BACKUP_LOC}/srv/videos /srv/videos
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully restored /srv/videos"
        else
          loggit "FAIL" "Failed to restore /srv/videos, aborting..."
          exit 1
        fi

        loggit "INFO" "Restoring /srv/images, please wait..."
        cp -pr ${BACKUP_LOC}/srv/images /srv/images 
        if [[ $? -eq 0 ]]; then
          loggit "PASS" "Successfully restored /srv/images"
        else
          loggit "FAIL" "Failed to restore /srv/images, aborting..."
          exit 1
        fi

        # Ensure previously installed environment has correct ownership/permissions
        sudo chown ${USER}:${USER} /srv/audio
        sudo chown ${USER}:www-data /srv /srv/images /srv/images/thumb /srv/videos
        sudo chmod 755 /srv
        sudo chmod 775 /srv/audio /srv/images /srv/images/thumb /srv/videos

      else
        loggit "FAIL" "Required space for restore is ${RequiredSpace} MB and Free space is only ${FreeSpace} MB, aborting..."
        exit 1
      fi

    else
    
      loggit "INFO" "${BACKUP_LOC}/srv directory not found, skipping restore..."

    fi
       
  else

    # Restoring /srv_staged as /srv so no extra space or time is required
    if [[ -d /srv_staged ]]; then
      loggit "INFO" "UnStaging /srv_staged as /srv"
      sudo mv /srv_staged /srv
      # Ensure previously installed environment has correct ownership/permissions
      sudo chown ${USER}:${USER} /srv/audio
      sudo chown ${USER}:www-data /srv /srv/images /srv/images/thumb /srv/videos
      sudo chmod 755 /srv
      sudo chmod 775 /srv/audio /srv/images /srv/images/thumb /srv/videos
    else
      loggit "FAIL" "/srv_staged does not exist, aborting..."
      exit 1
    fi

  fi


  if [[ -f ${BACKUP_LOC}/settings.yml ]]; then
    # Keep github original
    if [[ ! -f ${HOME}/raspberry-noaa-v2/config/settings.yml.original ]]; then
      if [[ -f ${HOME}/raspberry-noaa-v2/config/settings.yml ]]; then
        loggit "INFO" "Backing up GitHub settings.yml as settings.yml.original"
        cp -pr ${HOME}/raspberry-noaa-v2/config/settings.yml ${HOME}/raspberry-noaa-v2/config/settings.yml.original
      fi
    fi

    # Check for missing parameters from backup settings.yml that exist in latest Github version and merge them in if found
    PARMS_REQUIRED=/tmp/parameters_required
    PARMS_FOUND=/tmp/parameters_found
    NEED_NEWFILE=0
    NEWFILE_CREATED=0
    NEWFILE=/tmp/settings.yml
    COUNT=$(cat ${BACKUP_LOC}/settings.yml | wc -l)
    LINE=$((${COUNT} - 1))

    # Skip lines starting with # and skip blank lines and list the parameter
    cat ${HOME}/raspberry-noaa-v2/config/settings.yml.original | grep -Ev "^#|^---|^\...|^[[:blank:]]*$" | awk -F":" '{print $1}'  > /tmp/parameters_required
    cat ${BACKUP_LOC}/settings.yml | grep -Ev "^#|^---|^\...|^[[:blank:]]*$" | awk -F":" '{print $1}'  > /tmp/parameters_found

    # Search for missing parameters and append them to users settings.yml file
    while IFS= read -r parm; do
      vFOUND=$(grep ${parm} ${PARMS_FOUND} | wc -l)
      if [[ ${vFOUND} -eq 0 ]]; then
        NEED_NEWFILE=1
        if [[ ${NEWFILE_CREATED} -eq 0 ]]; then
          NEWFILE_CREATED=1
          cat ${BACKUP_LOC}/settings.yml | head -${COUNT} > ${NEWFILE}
          echo "" >> ${NEWFILE}
          echo "# The following parameters were added" >> ${NEWFILE}
        fi
        cat ${HOME}/raspberry-noaa-v2/config/settings.yml.original | grep ${parm} >> ${NEWFILE}
      fi
    done < ${PARMS_REQUIRED}

    if [[ ${NEWFILE_CREATED} -eq 1 ]]; then
      echo "..." >> ${NEWFILE}
      cp -pr ${NEWFILE} ${HOME}/raspberry-noaa-v2/config/settings.yml
      if [[ $? -eq 0 ]]; then
        loggit "PASS" "Successfully merged settings.yml"
      else
        loggit "FAIL" "Failed to merge settings.yml"
      fi
    else
      # No new setting needing to be merged, so lets restore the users original file back
      cp -pr ${BACKUP_LOC}/settings.yml ${HOME}/raspberry-noaa-v2/config/settings.yml
      if [[ $? -eq 0 ]]; then
        loggit "PASS" "Successfully restored settings.yml"
      else
        loggit "FAIL" "Failed to restore settings.yml, aborting..."
        exit 1
      fi
    fi

  else
    loggit "FAIL" "${BACKUP_LOC}/settings.yml not found, aborting..."
    exit 1
  fi

  if [[ -f ${BACKUP_LOC}/annotation.html.j2 ]]; then
    # Keep github original
    if [[ ! -f ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2.original ]]; then
      if [[ -f ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2 ]]; then
        cp -pr ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2 ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2.original
      fi
    fi
    cp -pr ${BACKUP_LOC}/annotation.html.j2 ${HOME}/raspberry-noaa-v2/config/annotation/annotation.html.j2
    if [[ $? -eq 0 ]]; then
      loggit "PASS" "Successfully restored annotation.html.j2"
    else
      loggit "FAIL" "Failed to restore annotation.html.j2, aborting..."
      exit 1
    fi
  else
    loggit "FAIL" "${BACKUP_LOC}/annotation.html.j2, not found, aborting..."
    exit
  fi

  if [[ -f ${BACKUP_LOC}/panel.db ]]; then
    # Keep github original
    if [[ ! -f ${HOME}/raspberry-noaa-v2/db/panel.db.original ]]; then
      if [[ -f ${HOME}/raspberry-noaa-v2/db/panel.db ]]; then
        cp -pr ${HOME}/raspberry-noaa-v2/db/panel.db ${HOME}/raspberry-noaa-v2/db/panel.db.original
      fi
    fi
    cp -pr ${BACKUP_LOC}/panel.db ${HOME}/raspberry-noaa-v2/db/panel.db
    if [[ $? -eq 0 ]]; then
      loggit "PASS" "Successfully backed up panel.db"
    else
      loggit "FAIL" "Failed to backup panel.db, aborting..."
      exit 1
    fi
  else
    loggit "FAIL" "${HOME}/raspberry-noaa-v2/db/panel.db, not found, aborting..."
    exit
  fi

}

if [[ ${vMODE} == "backup" ]]; then
  stage=0
  backup
elif [[ ${vMODE} == "backup_stage" ]]; then
  stage=1
  backup
elif [[ ${vMODE} == "restore" ]]; then
  stage=0
  restore
elif [[ ${vMODE} == "restore_stage" ]]; then
  stage=1
  restore
fi

secs_to_human "$(($(date +%s) - ${start}))"
