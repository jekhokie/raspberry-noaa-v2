#!/usr/bin/env python3
"""Publish a single image to an Instagram Business account via the Graph API.

Usage:
    push_instagram.py "<annotation>" "<image_filename>" "<website>"

The image must already be reachable at https://<website>/images/<image_filename>,
must be a JPEG (Instagram does not accept PNG via the API), and the account
must be an Instagram Business or Creator account linked to a Facebook Page.
Reads ~/.instagram.conf for INSTAGRAM_ACCESS_TOKEN and INSTAGRAM_ACCOUNT_ID.
"""

import os
import sys
import time

import requests

GRAPH_API_VERSION = "v25.0"
GRAPH_URL = f"https://graph.facebook.com/{GRAPH_API_VERSION}"


def parse_instagram_config(file_path):
    access_token = None
    account_id = None
    with open(file_path, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip("'\"")
            if key == "INSTAGRAM_ACCESS_TOKEN":
                access_token = value
            elif key == "INSTAGRAM_ACCOUNT_ID":
                account_id = value
    return access_token, account_id


def create_container(account_id, access_token, image_url, caption):
    url = f"{GRAPH_URL}/{account_id}/media"
    payload = {
        "image_url": image_url,
        "caption": caption,
        "access_token": access_token,
    }
    r = requests.post(url, data=payload, timeout=60)
    try:
        result = r.json()
    except ValueError:
        r.raise_for_status()
        raise
    if "id" not in result:
        raise RuntimeError(f"Container creation failed: {result}")
    return result["id"]


def wait_for_container(container_id, access_token, max_wait=180, interval=3):
    """Poll /{container_id}?fields=status_code until FINISHED, ERROR, or EXPIRED."""
    url = f"{GRAPH_URL}/{container_id}"
    params = {"fields": "status_code,status", "access_token": access_token}
    waited = 0
    while waited < max_wait:
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        result = r.json()
        status = result.get("status_code")
        if status == "FINISHED":
            return
        if status in ("ERROR", "EXPIRED"):
            raise RuntimeError(f"Container {container_id} failed: {result}")
        time.sleep(interval)
        waited += interval
    raise TimeoutError(
        f"Container {container_id} did not reach FINISHED within {max_wait}s"
    )


def publish_container(account_id, access_token, container_id):
    url = f"{GRAPH_URL}/{account_id}/media_publish"
    payload = {"creation_id": container_id, "access_token": access_token}
    r = requests.post(url, data=payload, timeout=60)
    try:
        result = r.json()
    except ValueError:
        r.raise_for_status()
        raise
    if "id" not in result:
        raise RuntimeError(f"Publish failed: {result}")
    return result


def main():
    if len(sys.argv) < 4:
        sys.exit("Usage: push_instagram.py <annotation> <image_filename> <website>")

    annotation = sys.argv[1]
    image = sys.argv[2]
    website = sys.argv[3]

    config_path = os.path.expanduser("~/.instagram.conf")
    access_token, account_id = parse_instagram_config(config_path)
    if not access_token or not account_id:
        sys.exit(
            "Missing INSTAGRAM_ACCESS_TOKEN or INSTAGRAM_ACCOUNT_ID in ~/.instagram.conf"
        )

    image_url = f"https://{website}/images/{image}"
    serbian_flag = "\U0001F1F7\U0001F1F8"
    hashtags = (
        "#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather "
        "#weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr "
        "#gpredict #raspberrypi #RN2 #ISS"
    )
    caption = f"{serbian_flag} {annotation}\n\n{hashtags}"


    container_id = create_container(account_id, access_token, image_url, caption)
    print(f"Container created: {container_id}")

    wait_for_container(container_id, access_token)
    print("Container FINISHED, publishing...")

    result = publish_container(account_id, access_token, container_id)
    print(f"Published. Media id: {result.get('id', '?')}")


if __name__ == "__main__":
    main()
