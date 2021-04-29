![Raspberry NOAA](../assets/header_1600_v2.png)

There is an ability to "prune" images to maintain space on your Raspberry Pi. This can be done one of 2 ways, detailed below.
In either case, to adjust the configurations for these, update the respective parameter in the `config/settings.yml`
file and re-run the `install_and_upgrade.sh` script to propagate your settings *BEFORE* creating the cron jobs.

**NOTE**: Both of these prune scripts delete the associated files and database records for the captures that are in scope.
Make sure this is what you want as once the script has run and the captures are deleted, they will not be recoverable.

## Prune Oldest n Captures

This script, named `scripts/prune_scripts/prune_oldest.sh`, is used to prune the oldest `n` number of captures, where `n` is
configured as the `delete_oldest_n` parameter in `config/settings.yml`. This is an example of a cron job that is
configured to run nightly at midnight using this script:

```bash
# prune oldest n captures
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/scripts/prune_scripts/prune_oldest.sh") | crontab -
```

## Prune Captures Older Than n Days

This script, named `scripts/prune_scripts/prune_older_than.sh`, is used to prune all captures older than `n` days old, where
`n` is configured as the `delete_older_than_n` parameter in `config/settings.yml`. This is an example of a cron job
that is configured to run nightly at midnight using this script:

```bash
# prune captures older than n days
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/scripts/prune_scripts/prune_older_than.sh") | crontab -
```
