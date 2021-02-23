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

If you just want to hear from the pi itself you can plug in headphones to the pi and enter:

'rtl_fm -f 97.3e6 -M wbfm -s 200000 -r 48000 - | aplay -r 48000 -f S16_LE'

Replace 97.3 with a strong local FM station. If you have an FM trap or LNA you may need to remove them from the antenna feed.

# Schedule

This project uses [crontab](https://crontab.guru/) to schedule pass collections. To view the schedule of the scheduler,
run `crontab -l`, which will show the frequency of scheduling using the `schedule.sh` script (by default, midnight each
day). This script also downloads the kepler elements from the internet and creates [at](https://linux.die.net/man/1/at)
jobs for each pass for the current day.

To view the jobs created for each of the passes, execute the `atq` command. This will list all of the jobs and their
respective job ID. You can get specific details about the job (such as the command being executed) by running
`at -c <job_id>`, where `<job_id>` is the ID of the job from the `atq` command you wish to inspect.

# Setting Gain

'''rtl_test'''

will output all of your SDRs available gain settings.  Pick one that works, starting in the middle if you don't have a reference, and put it into your settings.yml file.

# Images and Audio

Images are stored in the `/srv/images` directory, and audio in `/srv/audio`. These directories are opened for access by
the webpanel to display in the browser.

Audio may not exist depending on how you configured your installation. By default, the framework will delete audio files
after images are created to preserve space on your Raspberry Pi. If you disabled deleting audio, the audio should obviously
still remain in its directory after image processing completes.

# Completely White Meteor-M 2 Images

It's possible that you received a good Meteor-M 2 audio capture but the processing appears to have produced a completely
white/blank image output. In these cases, it's likely that the calculated sun angle for the time of capture was below the
threshold of your `SUN_MIN_ELEV` parameter, resulting in processing the image using values assuming a night capture and
washing out the actual detail in the image. You can check whether this was the case by getting the epoch time at the start
of the capture (convert your local capture start time to epoch time using a tool such as
[epoch calculator](https://www.epochconverter.com/)) and passing it to the `sun.py` script to see what the sun angle was
(according to the script) at that time of capture:

```bash
$ python3 ./scripts/tools/sun.py 1613063493

33
```

If the output value (in the above case, 33 degrees) was less than your `SUN_MIN_ELEV` threshold, night processing of the
image occurred and, if the sun was actually bright enough in your area at that time, the image would be almost completely
white. To adjust this, lower your `SUN_MIN_ELEV` threshold.

# Images Not Showing for Captures

If you are missing images for captures you are fairly certain should have produced images (high elevation, for example),
it's possible you may be running into an issue where some versions of `rtl_fm` do not have a Bias-Tee option (`-T`) when
attempting to enable Bias-Tee. This framework specifically installs a version of `rtl_fm` that is compatible with the
Bias-Tee option, but if you are using another distribution that has the binary pre-installed and/or install another version
yourself, it's possible this may be causing the recording to crash when attempting to use the `-T` option if it's not
available in the version being used. To check if your `rtl_fm` version supports the Bias-Tee option, you can run the command
`rtl_fm -h`. This command will display all available flags for your version, which should indicate a `-T` option available if
supported.

It's recommended you use the binary installed with this framework. However, if you must install or use another version and
the version does not support enabling Bias-Tee, there are ways to force Bias-Tee to be on through the SDR drivers for some
SDR devices (see your device official documentation).

# Logs and settings files

To edit the main configuration file:
'nano $HOME/raspberry-pi-noaa-v2/config/settings.yml'

to view the generated file (do not edit this one):
'sudo nano .noaa/config'

To read the main log:

To see the scheduling job:

To see the scheduled passes:

To cancel a pass:


