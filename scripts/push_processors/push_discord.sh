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
IMAGE=$1
MESSAGE=$2

# check that the file exists and is accessible
if [ -f "${IMAGE}" ]; then 
  log "Sending message to Discord webhook" "INFO"
  curl -H "Content-Type: multipart/form-data" \
       -F file=@$IMAGE \
       -F "payload_json={\"content\":\"$MESSAGE\"}" \
       $DISCORD_WEBHOOK
else
  log "Could not find or access image/attachment - not sending message to Discord" "ERROR"
fi
