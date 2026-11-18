![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_instagram_push: true` will enable pushing all captured, processed
images to an Instagram page. See below headings for the sequence of steps required to enable this functionality.

## Enable Instagram Push for raspberry-noaa-v2

First, update your `config/settings.yml` file to set `enable_instagram_push: true`.

Finally, re-run the `./install_and_upgrade.sh` script to propagate the settings and install a sample/template
`/home/{{ target_user }}/.instagram.conf` configuration file.

## Instagram Configuration Requirements

In order to configure Instagram pushing, you will need a Facebook [Business account](https://www.facebook.com/business/help/1710077379203657?id=180505742745347) and an [Instagram Business account](https://business.instagram.com/getting-started) which will be [connected to the Facebook account](https://help.instagram.com/176235449218188) in order to successfully use the Facebook Graph API keys. Once you've created the Facebook and Instagram business accounts, you must then set the application permissions to be Read & Write and publish the app from the testing phase into the live phase. Note that the first API key you get will be short-lived and you need to obtain the permanent API key. Here is the [guide](https://elfsight.com/blog/how-to-get-facebook-access-token/#:~:text=Go%20to%20Facebook%20Developer%20account,.facebook.com%2Fapps.&text=Press%20Create%20App%20ID%20and,select%20Get%20User%20Access%20Token.) for that. To find out your Instagram business account ID, it is recommended to use [Meta Business suite](business.facebook.com). Log in with your Facebook or Instagram account into it and go to `Settings > Business assets > Instagram accounts` and click on your account listed below. You will see ID displayed under `Instagram account ID: ` in a number format.

Finally, for API key and your account ID, copy the following from the Facebook developer's interface to the
`/home/{{ target_user }}/.instagram.conf` file:

* **API Key**: `INSTAGRAM_ACCESS_TOKEN=""`
* **ID**: `INSTAGRAM_ACCOUNT_ID=""`

## Testing (Optional)

If you want to run a manual test to ensure the Instagram configurations are acceptable, you can run a quick test
from the command line and pass an actual image file to the command like so:

```bash
python3 ./scripts/push_processors/push_instagram.py "test annotation" "<web_server_name>" "test_image.jpg" ["test_image2.jpg" ...]
```

Note that the test image needs to be of appropriate dimensions for Instagram post, as they only allow specific aspect ratios and resolutions. This is taken care of automatically in the receive scripts by the RN2, but for testing, I'd suggest you use some stock square image from the internet.
If all goes well and the image paths passed are files that actually exist, you should see a new post on your
Instagram page! The image files must be in `/srv/images` and reachable from the internet at `https://<web_server_name>/images/<file>`, because Instagram downloads them from your server. One image is posted as a single post, 2-10 images as a carousel, and more than 10 are split into several evenly sized carousels. For Meteor, all images of the pass are posted as carousels, each fitted (not cropped) into 1440x1800, the largest size the Instagram API publishes. For NOAA, MSA and MSA-precip during the day, or MCIR and MCIR-precip during the night, are stitched together into one image.

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see posts with
images show up on your Instagram feed!
