#!/usr/bin/env python3

import os
import sys
import facebook as fb

def parse_facebook_config(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Initialize variable to store the access token
    access_token = None

    # Process each line in the file
    for line in lines:
        # Remove leading and trailing whitespaces from the line
        line = line.strip()

        # Skip empty lines or lines starting with a '#' (comments)
        if not line or line.startswith('#'):
            continue

        # Split the line into key and value using the '=' separator
        key, value = line.split('=', 1)

        # Remove leading and trailing whitespaces from the key and value
        key = key.strip()
        value = value.strip()

        # Check if the key is 'FACEBOOK_ACCESS_TOKEN'
        if key == 'FACEBOOK_ACCESS_TOKEN':
            access_token = value.strip('\'"')
            break  # No need to continue after finding the access token

    return access_token

config_path = os.path.expanduser("~/.facebook.conf")

ACCESS_TOKEN_KEY = parse_facebook_config(config_path)

bot = fb.GraphAPI(ACCESS_TOKEN_KEY)

imgs_id = []
annotation = sys.argv[1]
images = sys.argv[2]
img_list = images.split()

for img in img_list:
  photo = open(img, "rb")
  imgs_id.append(bot.put_photo(photo, album_id='me/photos',published=False)['id'])
  photo.close()

args = dict()
args["message"] = annotation + '\n\n#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #weather #weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS'
for img_id in imgs_id:
  key = "attached_media["+str(imgs_id.index(img_id))+"]"
  args[key] = "{'media_fbid': '"+img_id+"'}"

bot.request(path = '/me/feed', args = None, post_args = args, method = 'POST')