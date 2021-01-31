![Raspberry NOAA](assets/header_1600_v2.png)

**_This is a spinoff of the original [raspberry-noaa](https://github.com/reynico/raspberry-noaa) created by Nico - they have
graciously permitted me to push this project forward with a major refactor to enhance things such as usability, style, and general
updates. All original content has been preserved (as have all commits up to the point of this repo creation) to retain credit to the
original creators._**

Wanting to give this version a go but not sure what's involved to get from the original raspberry-noaa to raspberry-noaa-v2? Check
out this simple [migration document](docs/migrate_from_raspberry_noaa.md) that explains the few commands you need to run and retain
your original data!

# Raspberry NOAA (...and Meteor) V2

Most of the base code was built from the great work done by [haslettj](https://www.instructables.com/member/haslettj/) in their
[Instructables](https://www.instructables.com/id/Raspberry-Pi-NOAA-Weather-Satellite-Receiver/) post. Not credit is assumed for
original work and all credit goes to the original creator.

In addition, as noted above, this repo is based on the great original work that Nico did in his
[raspberry-noaa](https://github.com/reynico/raspberry-noaa) repository.

## Why a Version 2?

A lot of the work done by Nico and the original Instructables poster was absolutely fantastic and simple. However, as I started
using the framework, I found myself making a lot of changes but getting the changes into place in a manageable way was a bit difficult.
In discussing this with Nico, we agreed that there is a logical next maturity step for this framework, so I took this on to provide
a simple, one-command script and corresponding framework to manage and maintain the entire project when any changes occur, and
refactored the webpanel functionality significantly to enable better feature additions in the future.

## Compatibility

The original raspberry-noaa was tested on Raspberry Pi 2 and up. However, while it's possible this compatibility has been maintained
with raspberry-noaa-v2, this version was developed and tested on a Raspberry Pi 4 - it has not been exhaustively tested on other variants
of Raspberry Pi (but if you get it working on a version, please do submit a PR and mention it so this document can be updated!).

In addition, it's recommended that the [Raspberry Pi OS](https://www.raspberrypi.org/software/) operating system is used - this is the
OS that has been tested and proven working. If you do test with another OS - again, please submit a PR and let us know how it works out!

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

To install the product and get going, simply clone the project to the `pi` user's home directory, run a script, and provide the
inputs asked for:

```bash
cd $HOME
git clone https://github.com/jekhokie/raspberry-noaa-v2.git
cd raspberry-noaa-v2/
./install_and_upgrade.sh
```

Once the script completes, you can either follow the [migration document](docs/migrate_from_raspberry_noaa.md) (if you had previously
been using raspberry-noaa on this device) or, if this is a brand new setup, just visit the webpanel and get going!

## Upgrade

Want to get the latest and greatest content from the GitHub master branch? Easy - use the same script from the Install process
and all of your content will automatically upgrade (obviously you'll want to do this when there isn't a scheduled capture occurring
or about to occur). Note that the upgrade process will *only* ask you for parameters if they are new to the software being updated -
your original configurations will remain intact and used without you needing to get involved!

```bash
./install_and_update.sh
```

## Post Install

There are and will be future "optional" features for this framework. Below is a list of optional capabilities that you may wish
to enable/configure with links to the respective instructions:

* [Auto-Post to Twitter](docs/auto_post_to_twitter.md)

## Troubleshooting

If you're running into issues where you're not seeing imagery after passes complete or getting blank/strange images, you can check
out the [troubleshooting](docs/troubleshooting.md) document to try and narrow down the problem.

## Additional Feature Information

For additional information on some of the capabilities included in this framework, see below:

  - [ISS SSTV Reception and Decoding](docs/iss.md)
  - [Meteor M2 Full Decoding](docs/meteor.md)
