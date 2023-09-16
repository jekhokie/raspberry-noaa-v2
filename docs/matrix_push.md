![Raspberry NOAA](../assets/header_1600_v2.png)

In `config/settings.yml`, setting `enable_matrix_push: true` will enable pushing all captured, processed
images to a Matrix room. See below headings for the sequence of steps required to enable this functionality.

## Enable Matrix Push for raspberry-noaa-v2

First, update your `config/settings.yml` file to set `enable_matrix_push: true`.

Finally, re-run the `./install_and_upgrade.sh` script to propagate the settings and install a sample/template
`/home/{{ target_user }}/.matrix.conf` configuration file.

## Matrix Configuration Requirements

In order to configure Matrix pushing, you will need to have a matrix account.
You will need to know three things to configure the notifications:

* The alias or id of your room.
* The address of your matrix server.
* An access token.

The alias you can get from room settings for an existing room, or set one when creating the room.
The address and the access token you can get from the "Help and About" settings in Element web/desktop if you don't already know them.

Once you have these add them to a file named `/home/{{ target_user }}/.matrix.conf` so it looks like this:

```
MATRIX_HOMESERVER="https://matrix.org"
MATRIX_ROOM="#weather:matrix.org"
MATRIX_ACCESS_TOKEN="..."
```

## Testing (Optional)

If you want to run a manual test to test the matrix configuration, you can run a quick test
from the command line and pass an actual image file (or many) to the command like so:

```bash
./scripts/push_processors/push_matrix.sh "test annotation" \
                                         "/srv/images/NOAA-18-20210212-091356-MCIR.jpg" \
                                         "/srv/images/NOAA-19-20210311-060645-ZA.jpg"   \
                                         "/srv/images/NOAA-19-20210311-060645-spectrogram.png"
```

If all goes well and the image paths passed are files that actually exist, you should see new posts in your matrix room!

## Profit

Once the above have been performed, simply wait until your next capture occurs and you should then see posts with
images show up in your room.
