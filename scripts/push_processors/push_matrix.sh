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

roomid=$MATRIX_ROOM

# Convert Alias to ID
if [[ $roomid == \#* ]] ;
then
    encalias=$(jq -rn --arg u "$roomid" '$u|@uri')
    roomid=$(curl -X GET -H "Content-Type: application/json" "$HOMESERVER/_matrix/client/r0/directory/room/${encalias}" | jq -r .room_id)
fi

for imagefile in $IMAGES; do
    if [ ! -f "${imagefile}" ]; then
        log "Could not find image ${imagefile} to post to Matrix - ignoring" "WARN"
    else
        # Extract filename
        filename=$(basename $imagefile)

        # Extract Content type
        content_type=$(file -b --mime-type $imagefile)

        # Upload image, extract mxc URL
        uri=$(curl -X POST --data-binary "@${imagefile}" -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-Type: ${content_type}" "$HOMESERVER/_matrix/media/r0/upload?filename=${filename}" | jq -r .content_uri)

        # Send message with image
        curl -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" -X PUT -d "{ \"body\": \"${filename}\", \"msgtype\": \"m.image\", \"url\": \"${uri}\" }" "$HOMESERVER/_matrix/client/r0/rooms/${roomid}/send/m.room.message/$(date +%s)"
    fi
done

curl -H "Authorization: Bearer ${ACCESS_TOKEN}" -H "Content-Type: application/json" -X PUT -d "{ \"body\": \"${MESSAGE}\" }" "$HOMESERVER/_matrix/client/r0/rooms/${roomid}/send/m.room.message/$(date +%s)"
