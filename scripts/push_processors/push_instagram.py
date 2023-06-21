#!/usr/bin/env python3

import sys
import requests
import json

access_token = "YOUR_API_KEY_GOES_HERE"
instagram_account_id ='YOUR_INSTAGRAM_ID_GOES_HERE'

graph_url = 'https://graph.facebook.com/v17.0/'

annotation = sys.argv[1]
image = sys.argv[2]

def publish_image():
  #post_url = 'https://graph.facebook.com/v17.0/{}/media'.format(instagram_account_id)
  post_url = f'https://graph.facebook.com/v17.0/{instagram_account_id}/media'
  image_url = f'https://voxgalactica.com/images/{image}'

  payload = {
             'image_url': image_url,
             'caption': annotation,
             'access_token': access_token,
            }
  r = requests.post(post_url, data = payload)
  print(r.text)
  print("Media uploaded successfully!")

  results = json.loads(r.text)

  if 'id' in results:
    creation_id=results['id']
    second_url = f'https://graph.facebook.com/v17.0/{instagram_account_id}/media_publish'
    second_payload = {
                      'creation_id': creation_id,
                      'access_token': access_token,
                     }
    r = requests.post(second_url, data = second_payload)
    print(r.text)
    print("Image published to Instagram")
  else:
    print("Error while publishing image to Instagram!")

publish_image()
