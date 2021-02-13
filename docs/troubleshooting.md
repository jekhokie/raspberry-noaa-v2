![Raspberry NOAA](../assets/header_1600_v2.png)

If you're running into issues, there are some steps you can follow to troubleshoot.

# Log Output

The `at` jobs log their output and you will receive a linux mail in the `pi` user's mailbox with the script
results after the pass and processing completes. Use the `mail` application on the command line to view the mail
messages and investigate the log outputs for any indications of errors.

In addition, all detailed log output is now captured in the directory `/var/log/raspberry-noaa-v2/` as well - check
the `output.log` files in this directory for detailed capture and processing information!

# USB Access Permission

If you inspect the mail output from your scheduled runs and see a message related to the following, it likely means
the udev rules put in place by the installer are not active (likely because you have not activated them or, more
specifically, rebooted your Pi after the initial installation). An error will look similar to the following:

```bash
Using device 0: Generic RTL2832U OEM
usb_open error -3
Please fix the device permissions, e.g. by installing the udev rules file rtl-sdr.rules
Failed to open rtlsdr device #0.
```

If you see the above, the best way to handle this is to reboot your Pi so the udev rules put in place by the installer
are activated and any other items requiring the reboot are sufficiently "kicked" for the next pass.

# Reception

The first thing to test is reception, which will validate that the antenna, reception line, reception hardware, and
software are all working correctly. There is a [scripts/testing/test_reception.sh](scripts/testing/test_reception.sh)
script that can be used to perform broadcast FM capture, allowing for tuning and adjustments. To use this, SSH to your
Raspberry Pi and perform the following:

```bash
cd $HOME/raspberry-noaa-v2/

# specify a frequency to use with the script
./scripts/testing/test_reception.sh 90.3
```

Then, open another terminal either on the Raspberry Pi or on another device that can reach the Pi (on the network)
and perform the following:

```bash
# replace <raspberry_pi_ip> with the IP of your Raspberry Pi
ncat <raspberry_pi_ip> 8073 | play -t mp3 -
```

The frequency used for the `test_reception.sh` script should be heard and can be used for tuning. If you're not hearing
anything, it's possible one of several things is wrong such as driver installation, USB configuration, etc. and a Google
search is likely your next best bet.

# Schedule

This project uses [crontab](https://crontab.guru/) to schedule pass collections. To view the schedule of the scheduler,
run `crontab -l`, which will show the frequency of scheduling using the `schedule.sh` script (by default, midnight each
day). This script also downloads the kepler elements from the internet and creates [at](https://linux.die.net/man/1/at)
jobs for each pass for the current day.

To view the jobs created for each of the passes, execute the `atq` command. This will list all of the jobs and their
respective job ID. You can get specific details about the job (such as the command being executed) by running
`at -c <job_id>`, where `<job_id>` is the ID of the job from the `atq` command you wish to inspect.

# Images and Audio

Images are stored in the `/srv/images` directory, and audio in `/srv/audio`. These directories are opened for access by
the webpanel to display in the browser.

Audio may not exist depending on how you configured your installation. By default, the framework will delete audio files
after images are created to preserve space on your Raspberry Pi. If you disabled deleting audio, the audio should obviously
still remain in its directory after image processing completes.

In addition, there is an ability to "prune" images to maintain space on your Raspberry Pi. This can be done one of 2 ways,
detailed below. In either case, to adjust the configurations for these, update the respective parameter in the `config/settings.yml`
file and re-run the `install_and_upgrade.sh` script to propagate your settings *BEFORE* creating the cron jobs.

**NOTE**: Both of these prune scripts delete the associated files and database records for the captures that are in scope.
Make sure this is what you want as once the script has run and the captures are deleted, they will not be recoverable.

## Prune Oldest n Captures

This script, named `scripts/prune_scripts/prune_oldest.sh`, is used to prune the oldest `n` number of captures, where `n` is
configured as the `delete_oldest_n` parameter in `config/settings.yml`. This is an example of a cron job that is
configured to run nightly at midnight using this script:

```bash
# prune oldest n captures
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/scripts/prune_oldest.sh") | crontab -
```

## Prune Captures Older Than n Days

This script, named `scripts/prune_scripts/prune_older_than.sh`, is used to prune all captures older than `n` days old, where
`n` is configured as the `delete_older_than_n` parameter in `config/settings.yml`. This is an example of a cron job
that is configured to run nightly at midnight using this script:

```bash
# prune captures older than n days
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/scripts/prune_older_than.sh") | crontab -
```

# Completely White Meteor-M 2 Images

It's possible that you received a good Meteor-M 2 audio capture but the processing appears to have produced a completely
white/blank image output. In these cases, it's likely that the calculated sun angle for the time of capture was below the
threshold of your `SUN_MIN_ELEV` parameter, resulting in processing the image using values assuming a night capture and
washing out the actual detail in the image. You can check whether this was the case by getting the epoch time at the start
of the capture (convert your local capture start time to epoch time using a tool such as
[epoch calculator](https://www.epochconverter.com/)) and passing it to the `sun.py` script to see what the sun angle was
(according to the script) at that time of capture:

```bash
$ python3 ./scripts/sun.py 1613063493

33
```

If the output value (in the above case, 33 degrees) was less than your `SUN_MIN_ELEV` threshold, night processing of the
image occurred and, if the sun was actually bright enough in your area at that time, the image would be almost completely
white. To adjust this, lower your `SUN_MIN_ELEV` threshold.
