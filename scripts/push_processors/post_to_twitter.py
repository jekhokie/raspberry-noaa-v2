#!/usr/bin/env python3
#
# Purpose: Send a list of images and corresponding annotation to a Twitter (X) feed.
#
# Uses the X API v2 endpoints only:
#   - POST https://api.x.com/2/media/upload   (replaces the retired v1.1 upload.twitter.com endpoint)
#   - POST https://api.x.com/2/tweets
# Both are signed with OAuth 1.0a user context, so the existing keys in ~/.tweepy.conf keep working.
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
from requests_oauthlib import OAuth1Session  # installed as a dependency of tweepy

MEDIA_UPLOAD_URL = 'https://api.x.com/2/media/upload'
CREATE_POST_URL = 'https://api.x.com/2/tweets'
MAX_IMAGE_BYTES = 5 * 1024 * 1024  # X limit for tweet_image
MAX_IMAGES_PER_POST = 4

HASHTAGS = ('\n\n#NOAA #NOAA15 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather #weathersats '
            '#APT #LRPT #wxtoimg #MeteorDemod #rtlsdr #gpredict #raspberrypi #RN2 #ISS')

# hints for the most common failures so the log says what to do
HINTS = {
  401: 'Unauthorized - keys/tokens are wrong or were regenerated; update ~/.tweepy.conf',
  402: 'Payment required - your X API pay-per-use credits are used up; top up at console.x.com',
  403: ('Forbidden - check the app has "Read and write" permissions (regenerate the access token '
        'after changing it) and that the app is attached to a Project'),
  429: 'Rate limited / spending limit reached - try again later or raise the limit in the X console',
}


def fail(step, resp):
  hint = HINTS.get(resp.status_code, '')
  print(f'ERROR: {step} failed with HTTP {resp.status_code}: {resp.text}')
  if hint:
    print(f'HINT: {hint}')
  sys.exit(1)


def main():
  if len(sys.argv) < 3:
    print('Usage: post_to_twitter.py "annotation" image1 [image2 ...]')
    sys.exit(1)

  try:
    session = OAuth1Session(
      os.environ['TWITTER_CONSUMER_API_KEY'],
      client_secret=os.environ['TWITTER_CONSUMER_API_KEY_SECRET'],
      resource_owner_key=os.environ['TWITTER_ACCESS_TOKEN'],
      resource_owner_secret=os.environ['TWITTER_ACCESS_TOKEN_SECRET'],
    )
  except KeyError as e:
    print(f'ERROR: missing environment variable {e} - check your ~/.tweepy.conf file')
    sys.exit(1)

  annotation = sys.argv[1]
  images = []
  for path in sys.argv[2:]:
    size = os.path.getsize(path)
    if size > MAX_IMAGE_BYTES:
      print(f'WARN: skipping {path} - {size / 1048576:.1f} MB is over the 5 MB X image limit')
      continue
    images.append(path)

  if not images:
    print('ERROR: no images small enough to post')
    sys.exit(1)

  groups = [images[i:i + MAX_IMAGES_PER_POST] for i in range(0, len(images), MAX_IMAGES_PER_POST)]

  for group in groups:
    media_ids = []
    for path in group:
      with open(path, 'rb') as f:
        resp = session.post(
          MEDIA_UPLOAD_URL,
          files={'media': (os.path.basename(path), f)},
          data={'media_category': 'tweet_image'},
          timeout=120,
        )
      if resp.status_code not in (200, 201):
        fail(f'media upload of {path}', resp)
      media_ids.append(resp.json()['data']['id'])

    resp = session.post(
      CREATE_POST_URL,
      json={'text': annotation + HASHTAGS, 'media': {'media_ids': media_ids}},
      timeout=60,
    )
    if resp.status_code not in (200, 201):
      fail('create post', resp)
    print(f'Posted https://x.com/i/status/{resp.json()["data"]["id"]} with {len(media_ids)} image(s)')


if __name__ == '__main__':
  main()
