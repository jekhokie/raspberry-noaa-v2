![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_facebook_push: true` will enable pushing all captured, processed
images to a Facebook page. See below headings for the sequence of steps required to enable this functionality.

## Enable Facebook Push for raspberry-noaa-v2

First, update your `config/settings.yml` file to set `enable_facebook_push: true`.

Finally, re-run the `./install_and_upgrade.sh` script to propagate the settings and install a sample/template
`/home/{{ target_user }}/.facebook.conf` configuration file.

## Facebook Configuration Requirements

In order to configure Facebook pushing, you will need a [Business account](https://www.facebook.com/business/help/1710077379203657?id=180505742745347) and a Facebook page which ID you will use to get the API key. Once you've created a business account
and created a Facebook page, you must then set the application permissions to be Read & Write and publish the app from the testing phase into the live phase. Note that the first API key you get will be short-lived and you need to obtain the permanent API key. Here is the [guide](https://elfsight.com/blog/how-to-get-facebook-access-token/#:~:text=Go%20to%20Facebook%20Developer%20account,.facebook.com%2Fapps.&text=Press%20Create%20App%20ID%20and,select%20Get%20User%20Access%20Token.) for that. Finally, for API key, copy the following from the Facebook developer's interface to the
`/home/{{ target_user }}/.facebook.conf` file:

* **API Key**: `FACEBOOK_ACCESS_TOKEN=""`

## Testing (Optional)

If you want to run a manual test to ensure the Facebook configurations are acceptable, you can run a quick test
from the command line and pass an actual image file (or many) to the command like so:

```bash
./scripts/push_processors/push_facebook.sh "test annotation" \
                                          "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
                                          "/srv/images/NOAA-19-20210311-060645-ZA.jpg"   \
                                          "/srv/images/NOAA-19-20210311-060645-spectrogram.png"
```

If all goes well and the image paths passed are files that actually exist, you should see a new post on your
Facebook page timeline!

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see posts with
images show up on your Facebook feed!
