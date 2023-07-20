#!/usr/bin/env python3

import os
import sys
import requests
import json

ACCESS_TOKEN = os.environ['INSTAGRAM_ACCESS_TOKEN']
ACCOUNT_ID = os.environ['INSTAGRAM_ACCOUNT_ID']

graph_url = 'https://graph.facebook.com/v17.0/'

annotation = sys.argv[1]
image = sys.argv[2]

def publish_image():
  #post_url = 'https://graph.facebook.com/v17.0/{}/media'.format(ACCOUNT_ID)
  post_url = f'https://graph.facebook.com/v17.0/{ACCOUNT_ID}/media'
  image_url = f'https://voxgalactica.com/images/{image}'

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
