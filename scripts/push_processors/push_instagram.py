#!/usr/bin/env python3

import os
import sys
import requests
import json

def parse_instagram_config(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Initialize variables to store the values
    access_token = None
    account_id = None

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

        # Check if the key is 'INSTAGRAM_ACCESS_TOKEN' or 'INSTAGRAM_ACCOUNT_ID'
        if key == 'INSTAGRAM_ACCESS_TOKEN':
            access_token = value.strip('\'"')
        elif key == 'INSTAGRAM_ACCOUNT_ID':
            account_id = value.strip('\'"')

    return access_token, account_id

config_path = os.path.expanduser("~/.instagram.conf")

ACCESS_TOKEN, ACCOUNT_ID = parse_instagram_config(config_path)

graph_url = 'https://graph.facebook.com/v17.0/'

annotation = sys.argv[1]
image = sys.argv[2]
website = sys.argv[3]

def publish_image():
  post_url = f'https://graph.facebook.com/v17.0/{ACCOUNT_ID}/media'
  image_url = f'https://{website}/images/{image}'

  payload = {
             'image_url': image_url,
             'caption': annotation + '\n\n#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #weather #weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS',
             'access_token': ACCESS_TOKEN,
            }
  r = requests.post(post_url, data = payload)
  print(r.text)
  print("Media uploaded successfully!")

  results = json.loads(r.text)

  if 'id' in results:
    creation_id=results['id']
    second_url = f'https://graph.facebook.com/v17.0/{ACCOUNT_ID}/media_publish'
    second_payload = {
                      'creation_id': creation_id,
                      'access_token': ACCESS_TOKEN,
                     }
    r = requests.post(second_url, data = second_payload)
    print(r.text)
    print("Image published to Instagram")
  else:
    print("Error while publishing image to Instagram!")

publish_image()
