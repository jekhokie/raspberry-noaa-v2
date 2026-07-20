#!/usr/bin/env python3

import os
import sys
from mastodon import Mastodon

def parse_mastodon_config(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Initialize variable to store the access token
    mastodon_access_token = None
    mastodon_server_instance_url = None

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

        # Check if the key is 'MASTODON_ACCESS_TOKEN' or 'MASTODON_SERVER_INSTANCE_URL'
        if key == 'MASTODON_ACCESS_TOKEN':
            mastodon_access_token = value.strip('\'"')
        elif key == 'MASTODON_SERVER_INSTANCE_URL':
            mastodon_server_instance_url = value.strip('\'"')

    return mastodon_access_token, mastodon_server_instance_url

config_path = os.path.expanduser("~/.mastodon.conf")

ACCESS_TOKEN, MASTODON_SERVER = parse_mastodon_config(config_path)

SerbianFlag = u'\U0001F1F7' + u'\U0001F1F8'

annotation = sys.argv[1]
images = []
for file in sys.argv[2:]:
  images.append(file)

# split images into groups (Mastodon allows maximum 4 per post)
if len(images) > 4:
  images = [ images[i:i+4] for i in range(0, len(images), 4) ]
else:
  images = [ images ]

# Create an instance of the Mastodon class
mastodon = Mastodon(
    access_token = ACCESS_TOKEN,
    api_base_url = MASTODON_SERVER
)

for image_group in images:
  # upload the images to Mastodon and obtain a media id link
  image_links = []
  for image in image_group:
    res = mastodon.media_post(image, 'image/jpeg')
    image_links.append(res)

  # create post
  mastodon.status_post(SerbianFlag + annotation + '\n\n#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather #weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS', media_ids=image_links)
