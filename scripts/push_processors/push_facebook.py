#!/usr/bin/env python3

import os
import sys
import facebook as fb

ACCESS_TOKEN_KEY = os.environ['FACEBOOK_ACCESS_TOKEN']

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