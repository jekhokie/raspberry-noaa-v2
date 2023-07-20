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

Finally, if you're looking for one of the cheapest ways to get started from an antenna perspective, check out
[this post](https://jekhokie.github.io/noaa/satellite/rf/antenna/sdr/2019/05/31/noaa-satellite-imagery-sdr.html), specifically around
how to use a cheap rabbit ears antenna as a dipole for capturing NOAA and Meteor images!

# Raspberry NOAA (...and Meteor) V2

NOAA and Meteor-M 2 satellite imagery capture setup for the Raspberry Pi!

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

These images are not always up to speed with the latest code, but lots of folks find images are a great way to get started quickly!

## Quick Start - building latest from the source on this repo

Want to build your own, but don't want all the nitty-gritty details? 
Here's the quick-start - if you have questions, continue reading the rest of this README or
reach out by submitting an issue:

```bash
# update os localisation settings
sudo raspi-config

# install git
sudo apt-get -y install git

# clone repository
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/

# copy sample settings and update for your install
cp config/settings.yml.sample config/settings.yml
vi config/settings.yml

# perform install
./install_and_upgrade.sh
```

Once complete, follow the [migration document](docs/migrate_from_raspberry_noaa.md) if you want to migrate from the original raspberry-noaa
to this version 2 (keep your previous captures and make them visible).

In addition, if you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to handle self-signed certificates when attempting to visit your webpanel and enabling auth for the admin pages.

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
3. You need git installed to clone the repository - this can be done via `sudo apt-get -y install git`.
4. It is recommended to change your `pi` user default password after logging into the Raspberry Pi for the first time. While it is not
recommended that you expose a Pi instance to the public internet for access (unless you have a VERY strict process about security
patching, and even then it would still be questionable), updating your Pi user password is a decent first step for security.

## Install

To install the product and get going, simply clone the project to the `pi` user's home directory, set up your settings, and run the
install script:

```bash
# install git
sudo apt-get -y install git

# clone repository
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/

# copy sample settings and update for your install
cp config/settings.yml.sample config/settings.yml
vi config/settings.yml

# perform install
./install_and_upgrade.sh
```

Once the script completes, you can either follow the [migration document](docs/migrate_from_raspberry_noaa.md) (if you had previously
been using raspberry-noaa on this device) or, if this is a brand new setup, just visit the webpanel and get going!

**NOTE**: If you have elected to run a TLS-enabled web server, see [THIS LINK](docs/tls_webserver.md) for some additional information
on how to handle self-signed certificates when attempting to visit your webpanel and enabling auth for the admin pages.

## Upgrade

Want to get the latest and greatest content from the GitHub master branch? Easy - use the same script from the Install process
and all of your content will automatically upgrade (obviously you'll want to do this when there isn't a scheduled capture occurring
or about to occur). Note that once you pull the latest code down using git, you'll likely want to compare your `config/settings.yml`
file with the new code `config/settings.yml.sample` and include/incorporate any new or renamed configuration parameters.

**Note**: You can double-check that the configuration parameters in your `config/settings.yml` file are correctly aligned to the
expectations of the framework configurations (this is done by default now as part of the `install_and_upgrade.sh` script) by
running `./scripts/tools/validate_yaml.py config/settings.yml config/settings_schema.json`. The output of this script will
inform you whether there are any new configs that you need to add to your `config/settings.yml` file or if values provided for
parameters are not within range or of the expected format to help with reducing the strain on your eyes in comparing the files.

```bash
# pull down new code
cd $HOME/raspberry-noaa-v2/
git pull

# compare settings file:
#   config/settings.yml.sample with config/settings.yml
# and incorporate any changes/updates

# perform upgrade
./install_and_upgrade.sh
```

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

## Additional Feature Information

The decoding model has been changed with release 1.8 to default to using GNURADIO based capture via Python for both Meteor 
(which was previously an option) and now also for NOAA. This will open the platform up for developers to integrate alternative hardware capture than rtl-sdr.

For additional information on some of the capabilities included in this framework, see below:

  - [Meteor M2 Full Decoding](docs/meteor.md)

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
*  **[mihajlo2003petkovic](https://github.com/mihajlo2003petkovic)**: Updates to the web browser and general updating and debugging. Integrated MeteorDemod in `receive_meteor.sh` and shrunk code quite a bit in `receive_noaa.sh`.
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