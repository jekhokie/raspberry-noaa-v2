![Raspberry NOAA](header_1600.png)

# NOAA and Meteor automated capture using Raspberry PI
Most of the code and setup stolen from: [Instructables](https://www.instructables.com/id/Raspberry-Pi-NOAA-Weather-Satellite-Receiver/)

## New Features!
  - [Meteor M2 full decoding!](METEOR.md)
  - Nginx webserver to show images
  - Timestamp and satellite name overlay on every image
  - WXToIMG configured to create several images (HVC,HVCT,MCIR, etc) based on sun elevation
  - Pictures can be posted to Twitter. See more at [argentinasat twitter account](https://twitter.com/argentinasat)

## Install
There's an [install.sh](install.sh) script that does (almost) everything at once. If in doubt, see the [install guide](INSTALL.md)

## Post config
* [Setup Twitter auto posting feature](INSTALL.md#set-your-twitter-credentials)

## Hardware setup
Raspberry-noaa runs on Raspberry PI 2 and up. See the [hardware notes](HARDWARE.md)
