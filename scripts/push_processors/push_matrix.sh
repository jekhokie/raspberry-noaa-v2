#!/bin/bash
#
# Purpose: Send image and message to a matrix room
#
# Input parameters:
#   1. Description to be sent as a normal message after all the images
#   2+. List of image paths to send (can be 1-many)
#
# Example:
#   ./scripts/push_processors/push_matrix.sh "test annotation" "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
#                                                              "/srv/images/NOAA-18-20210212-091356-HVC.jpg" \
#                                                              "/srv/images/NOAA-18-20210212-091356-MCIR-precip.jpg"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"
. "$HOME/.matrix.conf"

# input params
MESSAGE=$1
shift
IMAGES=$@

# check that matrix is configured
if [ -z "${MATRIX_ACCESS_TOKEN}" ]; then
    log "No matrix access token defined check your ~/.matrix.conf file" "ERROR"
    exit 1
fi

if [ -z "${MATRIX_HOMESERVER}" ]; then
    log "No matrix homeserver URL defined check your ~/.matrix.conf file" "ERROR"
    exit 1
fi

if [ -z "${MATRIX_ROOM}" ]; then
    log "No matrix room address defined check your ~/.matrix.conf file" "ERROR"
    exit 1
fi

roomurl=$(jq -rn --arg u "$MATRIX_ROOM" '$u|@uri')

# Join the room to ensure we are in it and get the room id
roomid=$(curl -X POST -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" -H "Content-Type: ${content_type}" "$MATRIX_HOMESERVER/_matrix/client/r0/join/${roomurl}" | jq -r .room_id)

for imagefile in $IMAGES; do
    if [ ! -f "${imagefile}" ]; then
        log "Could not find image ${imagefile} to post to Matrix - ignoring" "WARN"
    else
        # Extract filename
        filename=$(basename $imagefile)

        # Extract Content type
        content_type=$(file -b --mime-type $imagefile)

        # Upload image, extract mxc URL
        uri=$(curl -X POST -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" -H "Content-Type: ${content_type}" --data-binary "@${imagefile}" "$MATRIX_HOMESERVER/_matrix/media/r0/upload?filename=${filename}" | jq -r .content_uri)

        # Send message with image
	image_log=$(curl -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" -H "Content-Type: ${content_type}" -X PUT -d "{ \"body\": \"${filename}\", \"msgtype\": \"m.image\", \"url\": \"${uri}\" }" "$MATRIX_HOMESERVER/_matrix/client/r0/rooms/${roomid}/send/m.room.message/$(date +%s)" 2>&1)
	log "${image_log}" "INFO"
    fi
done

sleep 1

message_log=$(curl -H "Authorization: Bearer $MATRIX_ACCESS_TOKEN" -H "Content-Type: ${content_type}" -X PUT -d "{ \"body\": \"${MESSAGE}\", \"msgtype\": \"m.text\" }" "$MATRIX_HOMESERVER/_matrix/client/r0/rooms/${roomid}/send/m.room.message/$(date +%s)" 2?&1)
log "${message_log}" "INFO"
