![Raspberry NOAA](../assets/header_1600_v2.png)

If you're running into issues, there are some steps you can follow to troubleshoot.

# Log Output

The `at` jobs log their output and you will receive a linux mail in the `pi` user's mailbox with the script
results after the pass and processing completes. Use the `mail` application on the command line to view the mail
messages and investigate the log outputs for any indications of errors.

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
software are all working correctly. There is a [scripts/test_reception.sh](scripts/test_reception.sh) script that
can be used to perform broadcast FM capture, allowing for tuning and adjustments. To use this, SSH to your
Raspberry Pi and perform the following:

```bash
cd $HOME/raspberry-noaa-v2/

# specify a frequency to use with the script
./scripts/test_reception.sh 90.3
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

In addition, there is an ability to "prune" images to maintain space on your Raspberry Pi, deleting the 10 oldest images
from the disk and the database. Note that this is a destructive operation that is non-recoverable, so be certain this is
what you want to be doing. If so, run the following command, which will configure the prune script to run each day at
midnight:

```bash
cat <(crontab -l) <(echo "1 0 * * * /home/pi/raspberry-noaa-v2/scripts/prune.sh") | crontab -
```
