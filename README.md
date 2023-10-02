![Raspberry NOAA](assets/header_1600_v2.png)

Looking for support, wanting to talk about new features, or just hang out? Come chat with us on [Discord!](https://discord.gg/A9w68pqBuc)

**_This is a spinoff of the original [raspberry-noaa](https://github.com/reynico/raspberry-noaa) created by Nico - they have
graciously permitted me to push this project forward with a major refactor to enhance things such as usability, style, and general
updates. All original content has been preserved (as have all commits up to the point of this repo creation) to retain credit to the
original creators. Please see the "Credits" section of this README for additional info and contributions from the fantastic
NOAA/METEOR community!._**

Wanting to give this version a go but not sure what's involved to get from the original raspberry-noaa to raspberry-noaa-v2? Check
out this simple [migration document](docs/migrate_from_raspberry_noaa.md) that explains the few commands you need to run and retain
your original data!

Finally, if you're looking for one of the cheapest ways to get started from an antenna perspective, check this out
[https://jekhokie.github.io/noaa/satellite/rf/antenna/sdr/2019/05/31/noaa-satellite-imagery-sdr.html], specifically around
how to use a cheap rabbit ears antenna as a dipole for capturing NOAA and Meteor images!

# Raspberry NOAA (...and Meteor) V2

NOAA and Meteor-M 2 satellite imagery capture setup for the regular 64 bit Debian Bullseye computers and Raspberry Pi!

As of the September 2023 raspberry-noaa-v2 officially works on any Debian Bullseye based distro! This project has been developed and tested on LMDE 5 "Elsie" which is similar to the original Linux Mint, although the regular Mint is based on Ubuntu, while LMDE is based directly on Debian (It's short for Linux Mint Debian Edition). It can be downloaded from here: [https://mirrors.layeronline.com/linuxmint/debian/lmde-5-cinnamon-64bit.iso](https://mirrors.layeronline.com/linuxmint/debian/lmde-5-cinnamon-64bit.iso)

See "Credits" for the awesome way this version of the framework came to be.

## Super Easy setup: Use a maintained image
Want a really simple way to get up and running? 

VE3ELB has been maintaining a pre-built image of Raspberry-Noaa-V2 ('RN2') over here:
[https://qsl.net/ve3elb/RaspiNOAA/](https://qsl.net/ve3elb/RaspiNOAA/)
Setup instructions are in the PDF that is included. 

There is also an image maintained by Jochen Köster DC9DD here. 
[https://www.qsl.net/do3mla/raspberry-pi-images.html](https://www.qsl.net/do3mla/raspberry-pi-images.html)
For interest Jochen's image is the base for this offgrid system in Northern Norway! 
[https://usradioguy.com/science/off-grid-apt-lrpt-satellite-ground-station/](https://usradioguy.com/science/off-grid-apt-lrpt-satellite-ground-station/)

There is also image by MihajloPi maintained at: [https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6](https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6)
This image is oriented towards the general user and doesn't come with much software installed other than necessary. It was built from the minimal desktop version of the Raspberry OS Bullseye.

These images are not always up to speed with the latest code, but lots of folks find images are a great way to get started quickly!

## Quick Start - building latest from the source on this repo

Want to build your own, but don't want all the nitty-gritty details? 
Here's the quick-start - if you have questions, continue reading the rest of this README or
reach out by submitting an issue:

```bash
# update os localisation settings like timezone, locale and WiFi country
sudo raspi-config

# install git
sudo apt install git -y

# clone repository
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/

# Edit settings to match your stations location, gain and other things
nano config/settings.yml

# perform install
./install_and_upgrade.sh
```

Once complete, follow the [migration document](docs/migrate_from_raspberry_noaa.md) if you want to migrate from the original raspberry-noaa
to this version 2 (keep your previous captures and make them visible).

In addition, if you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to set up admin login and get your Let's Encrypt signed TLS/SSL certificate.

To see what occurred during a capture event, check out the log file `/var/log/raspberry-noaa-v2/output.log`.

## Why a Version 2?

A lot of the work done by Nico and the original Instructables poster was absolutely fantastic and simple. However, as I started
using the framework, I found myself making a lot of changes but getting the changes into place in a manageable way was a bit difficult.
In discussing this with Nico, we agreed that there is a logical next maturity step for this framework, so I took this on to provide
a simple, one-command script and corresponding framework to manage and maintain the entire project when any changes occur, and
refactored the webpanel functionality significantly to enable better feature additions in the future.

Check out the release notes for fixes and enhancements for each of the various releases since the V1 split to V2!

Also, check out [THIS LINK](docs/webpanel_screenshots.md) for some screen shots of the webpanel, which is now mobile friendly!

## Compatibility

**NOTE: ONLY 32bit OS is supported : Recommended is 'Bullseye' Release.**

The original raspberry-noaa was tested on Raspberry Pi 2 and up. However, while it's possible this compatibility has been maintained
with raspberry-noaa-v2, this version was developed and tested on a Raspberry Pi 4 - it has not been exhaustively tested on other variants
of Raspberry Pi (but if you get it working on a version, please do submit a PR and mention it so this document can be updated!).

In addition, it's recommended that the Official Release of [Raspberry Pi OS](https://www.raspberrypi.org/software/) operating system is used 
**(not the very latest build)** - this is the OS that has been tested and proven working. 

As of September 2023, raspberry-noaa-v2 can also be installed on regular 64 bit computers running any Debian Bullseye-based distro. Itmhas been developed and tested on LMDE 5 "Elsie" which I also recommend for users coming from Windows, as it has many similarities. It can be downloaded here: [https://mirrors.layeronline.com/linuxmint/debian/lmde-5-cinnamon-64bit.iso](https://mirrors.layeronline.com/linuxmint/debian/lmde-5-cinnamon-64bit.iso)

If you do test with another OS - again, please submit a PR and let us know how it works out!

If you're interested in the details behind the original raspberry-noaa hardware compatibility tests, see the [hardware](docs/hardware.md)
document.

## wxtoimg License Terms Acceptance

Use of this framework assumes acceptance of the wxtoimg license terms and will automatically "accept" the terms as part of the installation.
You MUST review the license prior to installing this framework, which can be viewed under the "Terms and Conditions" section of the
[wxtoimg manual](https://wxtoimgrestored.xyz/downloads/wxgui.pdf). If you do not agree to the wxtoimg terms, please do not install or
use this framework.

## Prerequisites

Below are some prerequisites steps and considerations prior to installing this software:

1. Although the software certainly works on a Pi with a desktop environment installed, it would be best to use the minimal Raspberry Pi
OS (no desktop environment) to help avoid processing interference due to higher CPU/Memory consumption from the GUI components.
2. Update your localisation settings on your Pi prior to installing the software using the `sudo raspi-config` command, updating
"5 Localisation Options -> L1 Locale" and "5 Localisation Options -> L2 Timezone" settings to match your base station location for more
consistent time and language handling.
3. You need git installed to clone the repository - this can be done via `sudo apt install git -y`.
4. It is recommended that you do not use a default user "pi" and the default password "raspberry". While it is not
recommended that you expose a Pi instance to the public internet for access (unless you have a VERY strict process about security
patching, and even then it would still be questionable), updating your Pi user password is a decent first step for security.

## Install

To install the product, and get going if you're using 64 bit Debian Bullseye based computer, you first need to do stop sudo from asking to enter password. It will ensure all commands are handled well, and that our project can access superuser priviliges for certain things like moving files around in the audio and image directory etc.

To achieve this, run:

`echo "$USER ALL=(ALL) NOPASSWD: /bin/ls" | sudo tee -a /etc/sudoers`

Then reboot the computer:

`sudo reboot`

The following steps are for both regular computers and Raspberry Pi:

Clone the project to the user's home directory, set up your settings, and run the
install script:

```bash
# update the system
sudo apt update
sudo apt full-upgrade -y

# reboot the system
sudo reboot

# install git
sudo apt install git -y

# clone repository
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/

# update your settings file to match your location, gain and other setup-specific settings
nano config/settings.yml

# perform install
./install_and_upgrade.sh
```

Once the script completes, you can either follow the [migration document](docs/migrate_from_raspberry_noaa.md) (if you had previously
been using raspberry-noaa on this device) or, if this is a brand new setup, just visit the webpanel and get going!

**NOTE**: If you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to handle self-signed certificates when attempting to visit your webpanel and enabling auth for the admin pages.

## Upgrade

Want to get the latest and greatest content from the GitHub master branch? Easy!
Run:

`git pull`

inside the raspberry-noaa-v2 folder. If it complains about rhe changes to `settings.yml` file, make a backup of it somewhere else on your Pi like the desktop:

`mv config/settings.yml ~/Desktop`

and run:

`git pull`

Then, open settings file and edit it to match settings from the previous file.

***NOTE***: you may notice some extra variables or some variables missing. Don't worry, that's normal as some variables have been changed by the developers (either are taken care of automatically so were removed as they are reduntant now, or some new thing has been implemented, hence new variables).

If you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to handle self-signed certificates when attempting to visit your webpanel and enabling auth for the admin pages.

## Post Install

There are and will be future "optional" features for this framework. Below is a list of optional capabilities that you may wish
to enable/configure with links to the respective instructions:

* [Update Image Annotation Overlay](docs/annotation.md)
* [Pruning Old Images](docs/pruning.md)
* [Database Backups](docs/db_backups.md)
* [Emailing Images (IFTTT)](docs/emailing.md)
* [Pushing Images to Discord](docs/discord_push.md)

## Changing Configurations After Install

Want to make changes to either the base station functionality or webpanel settings? Simply update the `config/settings.yml` file
and re-run `./install_and_upgrade.sh` - the script will take care of the rest of the configurations!

## Troubleshooting

If you're running into issues where you're not seeing imagery after passes complete or getting blank/strange images, you can check
out the [troubleshooting](docs/troubleshooting.md) document to try and narrow down the problem. In addition, you can inspect the log
output file in `/var/log/raspberry-noaa-v2/output.log` to investigate potential errors or issues during capture events.

Still having problems? You can email MihajloPi at mihajlo.raspberrypi@gmail.com and be sure to send him the log so he can debug the errors!

## Additional Feature Information

The decoding model has been changed with release 3.0 to default to using satdump_live based capture via Python for both Meteor 
(which was previously an option) and now also for NOAA. This will open the platform up for developers to integrate alternative hardware capture than rtl-sdr.

For additional information on some of the capabilities included in this framework, see below:

  - [Meteor M2-3 Full Decoding](docs/meteor.md)

## Credits

The NOAA/METEOR image capture community is a group of fantastic, experienced engineers, radio operators, and tinkerers that all contributed in some way, shape,
or form to the success of this repository/framework. Below are some direct contributions and call-outs to the significant efforts made:

* **[haslettj](https://www.instructables.com/member/haslettj/)**: Did the hard initial work and created the post to instruct on how to build the base of this framework.
    * [Instructables](https://www.instructables.com/id/Raspberry-Pi-NOAA-Weather-Satellite-Receiver/) post had much of the content needed to kick this work off.
* **[Nico Rey](https://github.com/reynico)**: Initial creator of the [raspberry-noaa](https://github.com/reynico/raspberry-noaa) starting point for this repository.
* **[otti-soft](https://github.com/otti-soft/meteor-m2-lrpt)**: Meteor-M 2 python functionality for image processing.
* **[NateDN10](https://www.instructables.com/member/NateDN10/)**: Came up with the major enhancements to the Meteor-M 2 receiver image processing in "otti-soft"s repo above.
    * [Instructables](https://www.instructables.com/Raspberry-Pi-NOAA-and-Meteor-M-2-Receiver/) post had the details behind creating the advanced functionality.
* **[Dom Robinson](https://github.com/dom-robinson)**: Meteor enhancements, Satvis visualizations, and overall great code written that were incorporated into the repo.
    * Merge of functionality into this repo was partially created using his excellent fork of the original raspberry-noaa repo [here](https://github.com/dom-robinson/raspberry-noaa).
    * Continued pushing the boundaries on the framework capabilities.
* **[Colin Kaminski](https://www.facebook.com/holography)**: MAJOR testing assistance and submission of various enhancements and documentation.
    * Continuous assistance of community members in their search for perfect imagery.
* **[Mohamed Anjum Abdullah](https://www.facebook.com/MohamedAnjum9694/)**: Initial testing of the first release.
* **[Kyle Keen](http://kmkeen.com/rtl-power/)**: Programming a lot of features for our RTL-SDR Drivers.
* **[Pascal P.](https://github.com/Cirromulus)**: Frequency/spectrum analysis test scripts for visualizing frequency spectrum of environment.
* **[Socowi's Time Functionality](https://stackoverflow.com/a/50434292)**: Time parser to calculate end date for scanner scripts.
* **[Vince VE3ELB](https://github.com/ve3elb)**: Took on the invaluable task to create fully working images of RN2 for the PI and maintains [https://qsl.net/ve3elb/RaspiNOAA/](https://qsl.net/ve3elb/RaspiNOAA/).
*  **[mihajlo2003petkovic/MihajloPi](https://github.com/mihajlo2003petkovic)**: Integrated MeteorDemod for Meteor decoding and building it via Ansible, and also the awesome SatDump (option satdump_live) for both NOAA and Meteor live decoding. Shrunk and optimised both NOAA and Meteor receive scripts by quite much! Implemented Facebook and Instagram posting scripts and fixed Twitter posting script due to the API 2.0 error. Made localisation option reduntant (automatically is handled by the computer itself). Provided support for Airspy, HackRF and SDRPlay devices. Implemented website compression, edited the website landing page and improved the perceived image loading speed by using progressive JPEGs. Created [image](https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6) with Gary Day's help.
* **[Silvio I6CBI](https://www.qrz.com/db/I6CBI)**: General testing on Pi and PC running LMDE 5, helped debug WKHTMLTOPDF and integrate SDR Play devices for GNU Radio.
* **[Nicolas Delestre](https://twitter.com/DELESTRENicola2?t=NHkKPKWMsVQaeNv9vutYMA&s=09)**: General testing on Pi and PC running LMDE 5, lending his Pi and PC to MihajloPi virtually over SSH, VMC and TeamViewer for testing.
* **[Gary Day](https://www.facebook.com/profile.php?id=100068381156913&mibextid=ZbWKwL)**: Helped by lending his Raspberry Pis virtually over SSH, VNC and TeamViewer to MihajloPi for testing and creating image.
* **[Jérôme jp112sdl](https://github.com/jp112sdl)**: Implemented automatic discarding of Meteor M2-3 night passes since they give no visible image when it's in RGB123 mode.
## Contributing

Pull requests are welcome! Simply follow the below pattern:

1. Fork the repository to your own GitHub account.
2. `git clone` your forked repository.
3. `git checkout -b <my-branch-name>` to create a branch, replacing with your actual branch name.
4. Do some awesome feature development or bug fixes, committing to the branch regularly.
5. `git push origin <my-branch-name>` to push your branch to your forked repository.
6. Head back to the upstream `jekhokie/raspberry-noaa-v2` repository and submit a pull request using your branch from your forked repository.
7. Provide really good details on the development you've done within the branch, and answer any questions asked/address feedback.
8. Profit when you see your pull request merged to the upstream master and used by the community!

Make sure you keep your forked repository up to date with the upstream `jekhokie/raspberry-noaa-v2` master branch as this will make
development and addressing merge conflicts MUCH easier in the long run.

Happy coding (and receiving)!
