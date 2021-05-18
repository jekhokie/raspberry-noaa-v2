#!/bin/bash
#
# Purpose: Send image and message to a Twitter endpoint to post to a Twitter timeline.
#
# Input parameters:
#   1. Annotation
#   2+. List of image paths to send (can be 1-many)
#
# Example:
#   ./scripts/push_processors/push_twitter.sh "test annotation" "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
#                                                               "/srv/images/NOAA-18-20210212-091356-HVC.jpg" \
#                                                               "/srv/images/NOAA-18-20210212-091356-MCIR-precip.jpg"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
. "$HOME/.tweepy.conf"

# input params
MESSAGE=$1
shift
IMAGES=$@

# check that Twitter API configs are set
if [ -z "${TWITTER_CONSUMER_API_KEY}" ]; then
  log "No Twitter consumer key defined - check your ~/.tweepy.conf file" "ERROR"
  exit 1
fi

# check if any images can't be found/accessed
send_images=""
for image in $IMAGES; do
  if [ ! -f "${image}" ]; then
    log "Could not find image ${image} to post to Twitter - ignoring" "WARN"
  else
    send_images="${send_images} ${image}"
  fi
done

# check if any images are left to send after removing missing ones
if [ -z "${send_images}" ]; then
  log "No images to send to Twitter - failing" "ERROR"
  exit 1
else
  log "Posting images to Twitter feed:" "INFO"
  log "  ${send_images}" "INFO"
  post_resp=$(python3 "${PUSH_PROC_DIR}/post_to_twitter.py" "${MESSAGE}" ${send_images} 2>&1)
  log "${post_resp}" "INFO"
fi
