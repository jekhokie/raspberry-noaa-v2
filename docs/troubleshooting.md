![Raspberry NOAA](../assets/header_1600_v2.png)

If you're running into issues, there are some steps you can follow to troubleshoot. Worst case, run the support
script as `./support.sh` and paste the output into a GitHub issue against the repository, or better, visit us
on the Discord app [here](https://discord.gg/NywJEPP5) and paste the output so we can help you!

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

```rtl_fm -f 97.3e6 -M wbfm -s 200000 -r 48000 - | aplay -r 48000 -f S16_LE```

Replace 97.3 with a strong local FM station. If you have an FM trap or LNA you may need to remove them from the antenna feed.

# Noise level and interference sources

If you experience strange interference patterns or otherwise a bad reception, it may come from strong FM Radio stations,
PC switchmode powersupplies, or nearly anything else. If you want to analyze this, you can run these scripts overnight to see
whats floating around.

```bash
cd $HOME

raspberry-noaa-v2/scripts/testing/scan_for.sh 5h
```

This will scan a range for five hours and produce a heatmap waterfall image in your current working directory afterwards.
The output of the script will show the file that will be created.

Alternatively, you can call `start_scanning.sh` manually. If required (or curious), you can change the freqency to scan
there, too.

See [this link](./assets/images/scan_annotated.jpg) for an example output of the frequency analysis.

Please note that scanning will take precedence over scheduled tasks!

# Schedule

This project uses [crontab](https://crontab.guru/) to schedule pass collections. To view the schedule of the scheduler,
run `crontab -l`, which will show the frequency of scheduling using the `schedule.sh` script (by default, midnight each
day). This script also downloads the kepler elements from the internet and creates [at](https://linux.die.net/man/1/at)
jobs for each pass for the current day.

To view the jobs created for each of the passes, execute the `atq` command. This will list all of the jobs and their
respective job ID. You can get specific details about the job (such as the command being executed) by running
`at -c <job_id>`, where `<job_id>` is the ID of the job from the `atq` command you wish to inspect. The time listed is the
start time of the pass.

`atrm <job_id>` will remove a pass.

# Setting Gain

`rtl_test`

will output all of your SDRs available gain settings. Pick one that works, start in the middle if you don't have a reference,
and put it into your `config/settings.yml` file, then re-run `./install_and_upgrade.sh`. Setting gain to 0 will enable autogain
settings.

# Setting PPM

PPM is the error rate measured in Parts Per Million of your RTL-SDR device. While most RTL-SDR have a low PPM, they no two devices have the same PPM. 
To evaluate what your device's PPM is you can do so at the command line as follows:

``` 

$ rtl_test -p
Found 1 device(s):
  0:  Realtek, RTL2838UHIDIR, SN: 00000001

Using device 0: Generic RTL2832U OEM
Found Rafael Micro R820T tuner
Supported gain values (29): 0.0 0.9 1.4 2.7 3.7 7.7 8.7 12.5 14.4 15.7 16.6 19.7 20.7 22.9 25.4 28.0 29.7 32.8 33.8 36.4 37.2 38.6 40.2 42.1 43.4 43.9 44.5 48.0 49.6 
[R82XX] PLL not locked!
Sampling at 2048000 S/s.
Reporting PPM error measurement every 10 seconds...
Press ^C after a few minutes.
Reading samples in async mode...
Allocating 15 zero-copy buffers
lost at least 148 bytes
real sample rate: 2047936 current PPM: -31 cumulative PPM: -31
real sample rate: 2048004 current PPM: 2 cumulative PPM: -14
real sample rate: 2048024 current PPM: 12 cumulative PPM: -5
real sample rate: 2047967 current PPM: -16 cumulative PPM: -8
real sample rate: 2048007 current PPM: 4 cumulative PPM: -5
real sample rate: 2047987 current PPM: -6 cumulative PPM: -6
real sample rate: 2048084 current PPM: 41 cumulative PPM: 1
real sample rate: 2048055 current PPM: 27 cumulative PPM: 4
real sample rate: 2047981 current PPM: -9 cumulative PPM: 3
real sample rate: 2048009 current PPM: 4 cumulative PPM: 3
real sample rate: 2047975 current PPM: -12 cumulative PPM: 2
real sample rate: 2047887 current PPM: -55 cumulative PPM: -3
real sample rate: 2048116 current PPM: 57 cumulative PPM: 2
real sample rate: 2048020 current PPM: 10 cumulative PPM: 2
real sample rate: 2048027 current PPM: 14 cumulative PPM: 3 
...
```

As you can see from my example above the PPM for my card is beginning to average at around 2/3. 
The longer I leave the test running the more accurate that average will become. 
These PPM figures can be used in the settings.yml to offset the frequency accuracy. 
Generally they don't make a lot of difference unless you have a card which is wildly offset from '0'.


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

Below are some useful commands in a more summary fashion:

* Edit the main configuration file: `nano $HOME/raspberry-noaa-v2/config/settings.yml`
* View the generated configuration (do not edit this one): `less ~/.noaa-v2.conf`
* Read the main log file: `less /var/log/raspberry-noaa-v2/output.log`
* List the scheduled passes: `atq`
* Cancel a pass: `atrm <job_id>`
* Location of the tmp directory: `/home/{{ target_user }}/raspberry-noaa-v2/tmp/`
* Location of the wav files: `/srv/audio/noaa` and `/srv/audio/meteor`
* Location of the database: `/home/{{ target_user }}/raspberry-noaa-v2/db/panel.db`
* Location of the images: `/srv/images`

# Webpanel Expired Certificate

If you have enabled TLS for your webpanel and when visiting your webpanel the browser blocks you due to an expired certificate,
simply re-run the `install_and_upgrade.sh` script. This script has the ability to detect expired certificates (or expiring
within the next 24 hours) and will automatically remediate the problem by creating new certificates and installing them
appropriately. After running this script, you should be able to resume accessing the webpanel, but you will also likely need
to follw the instructions in the [TLS Webserver](tls_webserver.md) document regarding bypassing self-signed blocks in certain
browsers the very first time you access the webpanel since the certificate will be brand new to the browser.

# ngix Debugging Shortcuts
note: Older versions of Raspberry-noaa-V2 use php7.2

* Access log: `/var/log/nginx/access.log`
* Error log: `/var/log/nginx/error.log`
* FPM log: `/var/log/php7.4-fpm.log`
* Check for PHP-FPM: `sudo ps aux | grep 'php'`
* Check if the FPM service is installed: `sudo systemctl list-unit-files | grep -E 'php[^fpm]*fpm'`
* Check if the FPM service is running: `sudo systemctl is-active php7.4-fpm.service`
* Restart FPM service: `systemctl restart php7.4-fpm.service`
* Detailed check on the service: `systemctl status nginx`
* Start service: `systemctl start nginx`
* Check syntax `sudo nginx -t`
* Restart service: `systemctl restart nginx`
* Filter error logs: `tail -f /var/log/nginx/error.log`
* Check if nginx is binding to the ports: `netstat -plant | grep '80\|443'`
