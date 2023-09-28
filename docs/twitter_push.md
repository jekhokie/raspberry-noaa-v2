![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_twitter_push: true` will enable pushing all captured, processed
images to a Twitter feed. See below headings for the sequence of steps required to enable this functionality.

## Enable Twitter Push for raspberry-noaa-v2

First, update your `config/settings.yml` file to set `enable_twitter_push: true`.

Finally, re-run the `./install_and_upgrade.sh` script to propagate the settings and install a sample/template
`/home/{{ target_user }}/.tweepy.conf` configuration file.

## Twitter Configuration Requirements

In order to configure Twitter pushing, you will need a [Developer account](https://developer.twitter.com/)
and an application from which you can get the required credentials. Once you've created a developer account
and created an application, you must then set the application permissions to be `Read, Write, and
Direct Messages`. Finally, for Keys and Tokens, copy the following from the Twitter interface to the
`/home/{{ target_user }}/.tweepy.conf` file:

* **API Key**: `TWITTER_CONSUMER_API_KEY`
* **API Key Secret**: `TWITTER_CONSUMER_API_KEY_SECRET`
* **Access Token**: `TWITTER_ACCESS_TOKEN`
* **Access Token Secret**: `TWITTER_ACCESS_TOKEN_SECRET`

## Testing (Optional)

If you want to run a manual test to ensure the tweepy configurations are acceptable, you can run a quick test
from the command line and pass an actual image file (or many) to the command like so:

```bash
./scripts/push_processors/push_twitter.sh "test annotation" \
                                          "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
                                          "/srv/images/NOAA-19-20210311-060645-ZA.jpg"   \
                                          "/srv/images/NOAA-19-20210311-060645-spectrogram.png"
```

If all goes well and the image paths passed are files that actually exist, you should see a new post on your
Twitter feed!

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see posts with
images show up on your Twitter feed!
