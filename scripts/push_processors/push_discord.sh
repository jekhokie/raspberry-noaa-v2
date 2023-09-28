#!/bin/bash
#
# Purpose: Send image and message to a Discord webhook URL that will post the data to a Discord channel.
#
# Input parameters:
#   1. Image
#   2. Message
#
# Example:
#   ./scripts/push_processors/push_discord.sh /srv/images/NOAA-18-20210212-091356-MCIR.jpg "test"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
DISCORD_WEBHOOK=$1
IMAGE=$2
MESSAGE=$3

# check that the file exists and is accessible
if [ -f "${IMAGE}" ]; then 
  log "Sending message to Discord webhook" "INFO"
  push_log=$(curl -H "Content-Type: multipart/form-data" \
             -F file=@$IMAGE \
             -F "payload_json={\"content\":\"$MESSAGE\"}" \
	     $DISCORD_WEBHOOK 2>&1)
  log "${push_log}" "INFO"
else
  log "Could not find or access image/attachment - not sending message to Discord" "ERROR"
fi
