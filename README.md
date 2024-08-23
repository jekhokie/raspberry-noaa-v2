![Raspberry NOAA](assets/header_1600_v2.png)

Looking for support, wanting to talk about new features, or just hanging out? Come chat with us on [Discord!](https://discord.gg/A9w68pqBuc)

**_This is a spinoff of the original [raspberry-noaa](https://github.com/reynico/raspberry-noaa) created by Nico - they have
graciously permitted me to push this project forward with a major refactor to enhance things such as usability, style, and general
updates. All original content has been preserved (as have all commits up to the point of this repo creation) to retain credit to the
original creators. Please see the "Credits" section of this README for additional info and contributions from the fantastic
NOAA/METEOR community!._**

Wanting to give this version a go but not sure what's involved to get from the original raspberry-noaa to raspberry-noaa-v2? Check
out this simple [migration document](docs/migrate_from_raspberry_noaa.md) that explains the few commands you need to run and retain
your original data!

Finally, if you're looking for one of the cheapest ways to get started from an antenna perspective, check [this](https://jekhokie.github.io/noaa/satellite/rf/antenna/sdr/2019/05/31/noaa-satellite-imagery-sdr.html) out, specifically around how to use a cheap rabbit ears antenna as a dipole for capturing NOAA and Meteor images!

# Announcements

* 31.7.2024. We are sunsetting the legacy Debian Bullseye support for Raspberry Pi and x64 PCs. We have supported it for some time after the Bookworm support came out in May 2024. Thank you for using the raspberry-noaa-v2 project on these operating systems. New updates for SatDump and other features related to SatDump **will only be available for 64-bit Raspberry OS version Bookworm, and 64-bit Debian Bookworm-based Linux distributions for x64 PCs** as of now. If you'd like to continue receiving the new updates, we highly suggest you perform a full reinstallation of your operating system and conduct a fresh installation of raspberry-noaa-v2. It is possible to save previously received images before reinstalling the operating system by making a copy of `panel.db` file inside `~/raspberry-noaa-v2/db` directory and the whole `/srv` directory; restore these files after your new installation has finished. If you're satisfied with the current features available, you are free to use the system as-is. 

# Raspberry NOAA (...and Meteor) V2

NOAA and Meteor-M 2 satellite imagery capture setup for the regular 64-bit Debian Bookworm & Bullseye computers and 32-bit Raspberry Pi!

As of September 2023, raspberry-noaa-v2 officially works on any Debian-based distro! This project has been developed and tested on LMDE 6 "Faye" which is similar to the original Linux Mint, although the regular Mint is based on Ubuntu, while LMDE is based directly on Debian (Linux Mint Debian Edition). It can be downloaded from here: [https://mirrors.layeronline.com/linuxmint/debian/lmde-6-cinnamon-64bit.iso](https://mirrors.layeronline.com/linuxmint/debian/lmde-6-cinnamon-64bit.iso)

See "Credits" for the awesome way this version of the framework came to be.

## Super Easy setup: Use a maintained image
Want a really simple way to get up and running? 

VE3ELB has been maintaining a pre-built image of Raspberry-Noaa-V2 ('RN2') over here:
[https://qsl.net/ve3elb/RaspiNOAA/](https://qsl.net/ve3elb/RaspiNOAA/)
Setup instructions are in the PDF that is included. 

There is also an image maintained by Jochen Köster DC9DD here. 
[https://www.qsl.net/do3mla/raspberry-pi-images.html](https://www.qsl.net/do3mla/raspberry-pi-images.html)
For interest, Jochen's image is the base for this off-grid system in Northern Norway! 
[https://usradioguy.com/science/off-grid-apt-lrpt-satellite-ground-station/](https://usradioguy.com/science/off-grid-apt-lrpt-satellite-ground-station/)

There is also an image by MihajloPi maintained at: [https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6](https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6)
This image is oriented towards the general user and doesn't come with much software installed other than necessary. It was built from the minimal desktop version of the Raspberry OS Bullseye.

These images are not always up to speed with the latest code, but lots of folks find images are a great way to get started quickly!

## Quick Start - building the latest from the source on this repo

Want to build your own, but don't want all the nitty-gritty details? 
Here's a quick start - if you have questions, continue reading the rest of this README or
reach out by submitting an issue:

```bash
# update os localisation settings like timezone, locale and WiFi country, and expand the filesystem
sudo raspi-config

# install git
sudo apt install git -y

# clone repository
cd $HOME
git clone --depth 1 https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/

# Edit settings to match your station's location, gain and other things
nano config/settings.yml

# perform install
./install_and_upgrade.sh
```

Once complete, follow the [migration document](docs/migrate_from_raspberry_noaa.md) if you want to migrate from the original raspberry-noaa
to this version 2 (keep your previous captures and make them visible).

In addition, if you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to set up an admin login and get your Let's Encrypt signed TLS/SSL certificate.

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

**NOTE: ONLY 32-bit OS is supported : Recommended is 'Bookworm' Release.**

The original raspberry-noaa was tested on Raspberry Pi 2 and up. However, while this compatibility may have been maintained
with raspberry-noaa-v2, ~~this version was developed and tested on a Raspberry Pi 4 - it has not been exhaustively tested on other variants
of Raspberry Pi (but if you get it working on a version, please do submit a PR and mention it so this document can be updated!).~~, this version works on Pi 3, Pi 4 and Pi 5, and the variants of these models. If you can install 64 bit Debian Bookworm or Bullseye, it will probably work.

As of September 2023, raspberry-noaa-v2 can also be installed on regular 64-bit computers running **ANY** Debian Bookworm-based distro. ~~It has been developed and tested on LMDE 6 "Faye" which I also recommend for users coming from Windows, as it has many similarities. It can be downloaded here: [https://mirrors.layeronline.com/linuxmint/debian/lmde-6-cinnamon-64bit.iso](https://mirrors.layeronline.com/linuxmint/debian/lmde-6-cinnamon-64bit.iso)~~ After providing Bookworm support, the recommended version for PCs running RN2 is plain old Debian Bookworm. Desktop environment (like Gnome, KDE, Cinammon, XFCE...) doesn't matter, it only has to be 64-bit Debian.

If you test with another OS - again, please submit a PR and let us know how it works out!

If you're interested in the details behind the original raspberry-noaa hardware compatibility tests, see the [hardware](docs/hardware.md)
document.

## wxtoimg License Terms Acceptance

Use of this framework assumes acceptance of the wxtoimg license terms and will automatically "accept" the terms as part of the installation.
You MUST review the license prior to installing this framework, which can be viewed under the "Terms and Conditions" section of the
[wxtoimg manual](https://wxtoimgrestored.xyz/downloads/wxgui.pdf). If you disagree with the WXtoImg terms, please do not install or
use this framework.

## Prerequisites

Below are some prerequisites steps and considerations before installing this software:

1. Although the software certainly works on a Pi with a desktop environment installed, it would be best to use the minimal Raspberry Pi
OS (no desktop environment) to help avoid processing interference due to higher CPU/Memory consumption from the GUI components.
2. Update your localisation settings on your Pi prior to installing the software using the `sudo raspi-config` command, updating
"5 Localisation Options -> L1 Locale" and "5 Localisation Options -> L2 Timezone" settings to match your base station location for more
consistent time and language handling.
3. You need git installed to clone the repository - this can be done via `sudo apt install git -y`.
4. It's not recommended to use the default user "pi" and the default password "raspberry". While it is not
recommended that you expose a Pi instance to the public internet for access (unless you have a VERY strict process about security
patching, and even then it would still be questionable), updating your Pi user password is a decent first step for security.
5. When you perform the operating system install, please ensure the account name you choose for installing the RN2 software under is 9 characters or less.
This character limit is due to a known constraint with predict scheduling tool.

## Install

To install the product, and get going if you're using 64 64-bit Debian Bookworm-based computer, you first need to stop sudo from asking to enter a password. It will ensure all commands are handled well, and that our project can access superuser privileges for certain things like moving files around in the audio and image directory etc.

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
git clone --depth 1 https://github.com/jekhokie/raspberry-noaa-v2.git
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

Then, open the settings file and edit it to match the settings from the previous file.

***NOTE***: you may notice some extra variables or some variables missing. Don't worry, that's normal as some variables have been changed by the developers (either are taken care of automatically so were removed as they are redundant now, or some new thing has been implemented, hence new variables).

If you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to handle self-signed certificates when attempting to visit your webpanel and enabling auth for the admin pages.

## In-Situ Upgrade

Want to switch your existing RN2 installation to a different Github branch without loosing your settings and images?  

    **Introduction of RN2 Upgrade tool**

       ${HOME}/.rn2_utils/rn2_upgrade.sh https://github.com/jekhokie/raspberry-noaa-v2.git -b beta-development

        Just point to the branch you want to switch to by modifying the above line as needed.     

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


**Introduction of verification tool**

The verification tool can be used to help identify RN2 installation/configuration issues which may potentially prevent proper functioning of capture/decode/processing of APT telemetry data.

Execute the verification script by passing the required argument [ quick | full ]

  $HOME/raspberry-noaa-v2/scripts/tools/verification_tool/verification.sh quick

  Argument required:  ./verification.sh quick    or    ./verification.sh full
                        (~ 1 minute)                       (~ 5 minutes)

   Dryrun of binaries includes executing :

    nxing web page returned 200 OK status to confirm Web Portal is up.
    satdump live capture for 1 second to ensure it runs without error.
    wxmap generates an overlay map image which can be found       : $HOME/raspberry-noaa-v2/scripts/tools/verification_tool/test_files/wxtoimg-map-output.png
    wxtoimg generates MCIR enhanced image which can be founnd     :  $HOME/raspberry-noaa-v2/scripts/tools/verification_tool/test_files/wxtoimg-mcir-output.jpg
    meteordemod -h is executed to ensure it runs without error.

   When FULL mode is choosen meterdemod fully decodes a staged cadu file :

    meteordemod generates a full set of images which can be found :  $HOME/raspberry-noaa-v2/scripts/tools/verification_tool/test_files/tmp

Still having problems? You can email MihajloPi at mihajlo.raspberrypi@gmail.com and be sure to send him the log so he can debug the errors!

## Additional Feature Information

The decoding model has been changed with release 3.0 to default to using satdump_live based capture via Python for both Meteor 
(which was previously an option) and now also for NOAA. This will open the platform up for developers to integrate alternative hardware capture than RTL-SDR.

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
* **[Pascal P.](https://github.com/Cirromulus)**: Frequency/spectrum analysis test scripts for visualizing the frequency spectrum of the environment.
* **[Socowi's Time Functionality](https://stackoverflow.com/a/50434292)**: Time parser to calculate end date for scanner scripts.
* **[Vince VE3ELB](https://github.com/ve3elb)**: Took on the invaluable task of creating fully working images of RN2 for the PI and maintains [https://qsl.net/ve3elb/RaspiNOAA/](https://qsl.net/ve3elb/RaspiNOAA/).
* **[mihajlo2003petkovic/MihajloPi](https://github.com/mihajlo2003petkovic)**: Integrated MeteorDemod for Meteor decoding and building it via Ansible, and also the awesome SatDump (option satdump_live) for both NOAA and Meteor live decoding. Shrunk and optimised both NOAA and Meteor receive scripts by quite much! Implemented Facebook and Instagram posting scripts and fixed Twitter posting script due to the API 2.0 error. Made the localisation option redundant (automatically handled by the computer itself). Provided support for Airspy, HackRF and SDRPlay devices. Implemented website compression, edited the website landing page and improved the perceived image loading speed by using progressive JPEGs. Created [image](https://drive.google.com/drive/folders/1acaZ78VEROc7BWVtJ82C6qVrccA9CkR6) with Gary Day's help. Removed RTL-FM and GNU Radio and simplified workflow by quite a lot using exclusively SatDump for recording and demodulating signals live to wav/S files, then processing them later with WXtoImg or SatDump for NOAA, and MeteorDemod or SatDump for Meteor.
* **[Silvio I6CBI](https://www.qrz.com/db/I6CBI)**: General testing on Pi and PC running LMDE 5, helped debug WKHTMLTOPDF and integrate SDR Play devices for GNU Radio. Tested MiriSDR.
* **[Nicolas Delestre](https://twitter.com/DELESTRENicola2?t=NHkKPKWMsVQaeNv9vutYMA&s=09)**: General testing on Pi and PC running LMDE 5, lending his Pi and PC to MihajloPi virtually over SSH, VMC and TeamViewer for testing.
* **[Gary Day](https://www.facebook.com/profile.php?id=100068381156913&mibextid=ZbWKwL)**: Helped by lending his Raspberry Pis virtually over SSH, VNC and TeamViewer to MihajloPi for testing and creating an image.
* **[Jérôme jp112sdl](https://github.com/jp112sdl)**: Implemented automatic discarding of Meteor M2-3 night passes since they give no visible image when it's in RGB123 mode.
* **[patrice7560](https://meteo-schaltin.duckdns.org)**: Beta tester, helped in detecting and reporting errors ASAP for debugging.
* **[Richard AI4Y](https://www.qrz.com/db/AI4Y)**: Provided Debian 12 (Bookworm) support for Raspberry Pi, 64-bit Raspberry OS support, discovered the FFMPEG bug when creating spectrograms, solved atrm errors on the website, and several NTP and timezone issues in PHP, developed Verification Tool, Developed In-Situ Upgrade for switching repo's/branches, developed RN2 Utilities for backup/restore/stage, uninstall and upgrading, general warning cleanup of scripts, Made 32-bit wxtoimg run on 64-bit Debian, creates satdump/predict DEB files for armhf & arm64, general alpha and beta testing.
## Contributing

Pull requests are welcome! Simply follow the below pattern:

1. Fork the repository to your own GitHub account.
2. `git clone` your forked repository.
3. `git checkout -b <my-branch-name>` to create a branch, replacing it with your actual branch name.
4. Do some awesome feature development or bug fixes, committing to the branch regularly.
5. `git push origin <my-branch-name>` to push your branch to your forked repository.
6. Head back to the upstream `jekhokie/raspberry-noaa-v2` repository and submit a pull request using your branch from your forked repository.
7. Provide really good details on the development you've done within the branch, and answer any questions asked/address feedback.
8. Profit when you see your pull request merged to the upstream master and used by the community!

Make sure you keep your forked repository up to date with the upstream `jekhokie/raspberry-noaa-v2` master branch as this will make
development and addressing merge conflicts MUCH easier in the long run.

Happy coding (and receiving)!
