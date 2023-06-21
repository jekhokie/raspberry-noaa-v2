#!/usr/bin/env python3

import sys
import facebook as fb

access_token = "YOUR_API_KEY_GOES_HERE"

bot = fb.GraphAPI(access_token)

imgs_id = []
annotation = sys.argv[1]
images = sys.argv[2]
img_list = images.split()

for img in img_list:
  photo = open(img, "rb")
  imgs_id.append(bot.put_photo(photo, album_id='me/photos',published=False)['id'])
  photo.close()

args = dict()
args["message"] = annotation
for img_id in imgs_id:
  key = "attached_media["+str(imgs_id.index(img_id))+"]"
  args[key] = "{'media_fbid': '"+img_id+"'}"

bot.request(path = '/me/feed', args = None, post_args = args, method = 'POST')