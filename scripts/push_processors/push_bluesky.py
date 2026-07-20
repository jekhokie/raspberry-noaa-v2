#!/usr/bin/env python3

import os
import sys
from atproto import Client

def parse_bluesky_config(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Initialize variable to store the access token
    bluesky_username_and_server_instance_url = None
    bluesky_app_password = None

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

        # Check if the key is 'bluesky_username_and_server_instance_url' or 'bluesky_app_password'
        if key == 'bluesky_username_and_server_instance_url':
            bluesky_username_and_server_instance_url = value.strip('\'"')
        elif key == 'bluesky_app_password':
            bluesky_app_password = value.strip('\'"')

    return bluesky_username_and_server_instance_url, bluesky_app_password

config_path = os.path.expanduser("~/.bluesky.conf")

bluesky_username_and_server_instance_url, BLUESKY_APP_PASSWORD = parse_bluesky_config(config_path)

SerbianFlag = u'\U0001F1F7' + u'\U0001F1F8'

annotation = sys.argv[1]
images = []
for file in sys.argv[2:]:
  images.append(file)

# split images into groups (Bluesky allows maximum 4 per post)
if len(images) > 4:
  images = [ images[i:i+4] for i in range(0, len(images), 4) ]
else:
  images = [ images ]

client = Client()
client.login(bluesky_username_and_server_instance_url, BLUESKY_APP_PASSWORD)


post_text = SerbianFlag + annotation + '\n\n#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather #weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS'


image_data = []
for image_path in images:
  for i in range(0, 3):
    with open(image_path[i], 'rb') as f:
      image_data.append(f.read())
      client.send_images(text=post_text, images=image_data)