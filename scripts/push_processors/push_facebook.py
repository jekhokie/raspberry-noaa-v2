#!/usr/bin/env python3
"""Post one or more local images to a Facebook Page as a single multi-photo post.

Usage:
    push_facebook.py "<annotation>" "<space-separated-image-paths>"

Reads ~/.facebook.conf for FACEBOOK_ACCESS_TOKEN and FACEBOOK_PAGE_ID.
The access token must be a Page access token with pages_manage_posts and
pages_read_engagement permissions.
"""

import json
import os
import sys

import requests

GRAPH_API_VERSION = "v25.0"
GRAPH_URL = f"https://graph.facebook.com/{GRAPH_API_VERSION}"


def parse_facebook_config(file_path):
    access_token = None
    page_id = None
    with open(file_path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("'\"")
            if key == "FACEBOOK_ACCESS_TOKEN":
                access_token = value
            elif key == "FACEBOOK_PAGE_ID":
                page_id = value
    return access_token, page_id


def upload_unpublished_photo(page_id, access_token, image_path):
    """Upload a single photo with published=false. Returns the photo id."""
    url = f"{GRAPH_URL}/{page_id}/photos"
    with open(image_path, "rb") as fh:
        files = {"source": fh}
        data = {"published": "false", "access_token": access_token}
        r = requests.post(url, data=data, files=files, timeout=120)
    try:
        result = r.json()
    except ValueError:
        r.raise_for_status()
        raise
    if "id" not in result:
        raise RuntimeError(f"Upload failed for {image_path}: {result}")
    return result["id"]


def publish_feed_post(page_id, access_token, message, media_ids):
    """Publish one feed post that references all uploaded photos."""
    url = f"{GRAPH_URL}/{page_id}/feed"
    data = {"message": message, "access_token": access_token}
    for i, mid in enumerate(media_ids):
        # Must be valid JSON: double quotes, not single.
        data[f"attached_media[{i}]"] = json.dumps({"media_fbid": mid})
    r = requests.post(url, data=data, timeout=60)
    try:
        result = r.json()
    except ValueError:
        r.raise_for_status()
        raise
    if "id" not in result:
        raise RuntimeError(f"Feed post failed: {result}")
    return result


def main():
    if len(sys.argv) < 3:
        sys.exit("Usage: push_facebook.py <annotation> <space-separated-images>")

    annotation = sys.argv[1]
    img_list = [p for p in sys.argv[2].split() if p]
    if not img_list:
        sys.exit("No images provided.")

    config_path = os.path.expanduser("~/.facebook.conf")
    access_token, page_id = parse_facebook_config(config_path)
    if not access_token or not page_id:
        sys.exit("Missing FACEBOOK_ACCESS_TOKEN or FACEBOOK_PAGE_ID in ~/.facebook.conf")

    serbian_flag = "\U0001F1F7\U0001F1F8"
    hashtags = (
        "#NOAA #NOAA15 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather "
        "#weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr "
        "#gpredict #raspberrypi #RN2 #ISS"
    )
    message = f"{serbian_flag} {annotation}\n\n{hashtags}"


    media_ids = []
    for img in img_list:
        try:
            mid = upload_unpublished_photo(page_id, access_token, img)
            media_ids.append(mid)
            print(f"Uploaded {img} -> {mid}")
        except Exception as e:
            print(f"Failed to upload {img}: {e}", file=sys.stderr)

    if not media_ids:
        sys.exit("No photos uploaded; aborting.")

    result = publish_feed_post(page_id, access_token, message, media_ids)
    print(f"Posted {len(media_ids)} photo(s). Post id: {result.get('id', '?')}")


if __name__ == "__main__":
    main()
