#!/usr/bin/env python3
#
# Purpose: Send a list of images and corresponding annotation to a Twitter feed.
#
# Input parameters:
#   1. Annotation
#   2+. List of image paths to send (can be 1-many)
#
# Example:
#   ./scripts/push_processors/post_to_twitter.py "test annotation" "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
#                                                                  "/srv/images/NOAA-18-20210212-091356-HVC.jpg" \
#                                                                  "/srv/images/NOAA-18-20210212-091356-MCIR-precip.jpg"

import os
import sys
import tweepy

# get Twitter credentials
CONSUMER_KEY = os.environ['TWITTER_CONSUMER_API_KEY']
CONSUMER_SECRET = os.environ['TWITTER_CONSUMER_API_KEY_SECRET']
ACCESS_TOKEN_KEY = os.environ['TWITTER_ACCESS_TOKEN']
ACCESS_TOKEN_SECRET = os.environ['TWITTER_ACCESS_TOKEN_SECRET']

# create instance of tweepy for pushing
auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_TOKEN_KEY, ACCESS_TOKEN_SECRET)
api = tweepy.API(auth)
client = tweepy.Client(consumer_key=CONSUMER_KEY, consumer_secret=CONSUMER_SECRET, access_token=ACCESS_TOKEN_KEY, access_token_secret=ACCESS_TOKEN_SECRET)

# parse input annotation and images
annotation = sys.argv[1]
images = []
for file in sys.argv[2:]:
  images.append(file)

# split images into groups (twitter allows maximum 4 per post)
if len(images) > 4:
  images = [ images[i:i+4] for i in range(0, len(images), 4) ]
else:
  images = [ images ]

for image_group in images:
  # upload the images to Twitter and obtain a media id link
  image_links = []
  for image in image_group:
    res = api.media_upload(image)
    image_links.append(res.media_id)

  # create post
  client.create_tweet(text=annotation + '\n\n#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #weather #weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS', media_ids=image_links)
