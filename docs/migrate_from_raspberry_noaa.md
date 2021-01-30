![Raspberry NOAA](../assets/header_1600_v2.png)

# Migrating from raspberry-noaa (V1)

If you've already installed and have been using the original raspberry-noaa framework and want to give
this version (V2) a whirl, migrating is VERY easy and will retain your original data. Simply perform
the following, which will retain your original captures/audio in their original locations while making
copies of them in a parallel structure to run V2 (allowing you to switch back if you aren't satisfied
with V2).

**WARNING**: The below process assumes you've installed and configured raspberry-noaa (V1) and have
*NOT* made any changes to the code base or database. If you have modified anything, this process *WILL*
destroy or corrupt your data, so please read through the instructions below carefully and figure out how
to best proceed based on what you've changed in your configuration.

## Migration Process

First, follow the [installation](install.md) document to clone and install V2. Be assured that this install
process does *not* destroy any of your captures or audio - it sets up a completely different directory structure
that will scale better over time while maintaining the original directory structure of raspberry-noaa.

Once you've installed raspberry-noaa-v2, perform the following:

```bash
# copy the original database from v1 to v2 to retain metadata
cp $HOME/raspberry-noaa/panel.db $HOME/raspberry-noaa-v2/db/

# if you have any files in these directories from v1, transfer them using the following:
cp -rf /var/www/wx/images/* /srv/images/
cp -rf /var/www/wx/audio/* /srv/audio/noaa/
cp -rf /var/www/wx/meteor/audio/* /srv/audio/meteor/

# re-run schedule.sh to update the database with the latest passes
$HOME/raspberry-noaa-v2/scripts/schedule.sh
```

Finally, ensure the original cron job for scheduling is commented out or removed to avoid conflicting
scheduled jobs with the old and new versions. Execute `crontab -e` as the `pi` user to edit this file
and place a '#' character at the beginning of the line calling the `schedule.sh` script from the old
`raspberry-noaa/` directory (or delete the line), then save and quit the editor.

## Removing Old Data

If you've run and are satisfied with the raspberry-noaa-v2 framework, feel free to remove existing
resources to keep things clean and save space on existing copies of imagery. Specifically, feel free
to explore and (if desired) execute the following to remove some of the old content:

```bash
# remove the raspberry-noaa project directory (V1)
rm -rf $HOME/raspberry-noaa

# remove the raspberry-noaa webpanel (V1)
sudo rm -rf /var/www/wx

# remove the raspberry-noaa environment vars (V1)
rm $HOME/.noaa.conf
```
