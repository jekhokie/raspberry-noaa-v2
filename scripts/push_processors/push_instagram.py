#!/usr/bin/env python3
"""Publish one image, or a carousel of 2-10 images, to an Instagram Business account via the Graph API.

Usage:
    push_instagram.py "<annotation>" "<website>" "<image_filename>" ["<image_filename>" ...]

One image is posted as a normal post; 2-10 images are posted as a carousel.
More than 10 images are split into several evenly sized carousels (e.g. 11 -> 6 + 5,
23 -> 8 + 8 + 7), each captioned with its part number. Each image must already be reachable at
https://<website>/images/<image_filename>,
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


MAX_CAROUSEL_ITEMS = 10


def create_container(account_id, access_token, payload):
    url = f"{GRAPH_URL}/{account_id}/media"
    payload = dict(payload, access_token=access_token)
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
        result = r.json()
        if "error" in result:
            raise RuntimeError(f"Status check of container {container_id} failed: {result}")
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
        sys.exit('Usage: push_instagram.py "<annotation>" "<website>" "<image_filename>" ["<image_filename>" ...]')

    annotation = sys.argv[1]
    website = sys.argv[2]
    images = sys.argv[3:]

    config_path = os.path.expanduser("~/.instagram.conf")
    access_token, account_id = parse_instagram_config(config_path)
    if not access_token or not account_id:
        sys.exit(
            "Missing INSTAGRAM_ACCESS_TOKEN or INSTAGRAM_ACCOUNT_ID in ~/.instagram.conf"
        )

    image_urls = [f"https://{website}/images/{image}" for image in images]
    hashtags = (
        "#NOAA #NOAA15 #NOAA18 #NOAA19 #MeteorM2_3 #MeteorM2_4 #weather "
        "#weathersats #APT #LRPT #wxtoimg #MeteorDemod #rtlsdr "
        "#gpredict #raspberrypi #RN2 #ISS"
    )
    caption = f"{annotation}\n\n{hashtags}"

    # split into the fewest groups of <= 10, with sizes as even as possible (no lone leftover image)
    n_groups = -(-len(image_urls) // MAX_CAROUSEL_ITEMS)
    base, extra = divmod(len(image_urls), n_groups)
    groups, start = [], 0
    for i in range(n_groups):
        size = base + (1 if i < extra else 0)
        groups.append(image_urls[start:start + size])
        start += size

    failures = 0
    for part, group in enumerate(groups, 1):
        part_caption = caption
        if n_groups > 1:
            part_caption = f"{annotation} ({part}/{n_groups})\n\n{hashtags}"
            print(f"--- Post {part}/{n_groups}: {len(group)} image(s)")
        try:
            publish_group(account_id, access_token, group, part_caption)
        except Exception as e:  # keep going so one bad group doesn't block the rest
            failures += 1
            print(f"ERROR: post {part}/{n_groups} failed: {e}")

    if failures:
        sys.exit(f"{failures} of {n_groups} Instagram post(s) failed")


def publish_group(account_id, access_token, image_urls, caption):
    if len(image_urls) == 1:
        container_id = create_container(account_id, access_token,
                                        {"image_url": image_urls[0], "caption": caption})
        print(f"Container created: {container_id} ({image_urls[0]})")
    else:
        children = []
        for image_url in image_urls:
            child_id = create_container(account_id, access_token,
                                        {"image_url": image_url, "is_carousel_item": "true"})
            print(f"Carousel item created: {child_id} ({image_url})")
            children.append(child_id)
        for child_id in children:
            wait_for_container(child_id, access_token)
        container_id = create_container(account_id, access_token, {
            "media_type": "CAROUSEL",
            "children": ",".join(children),
            "caption": caption,
        })
        print(f"Carousel container created: {container_id} with {len(children)} images")

    wait_for_container(container_id, access_token)
    print("Container FINISHED, publishing...")

    result = publish_container(account_id, access_token, container_id)
    print(f"Published. Media id: {result.get('id', '?')}")


if __name__ == "__main__":
    main()
