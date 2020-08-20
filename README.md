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

## How do I know if it is running properly?
This project is intended as a zero-maintenance system where you just power-up the Raspberry PI and wait for images to be received. However, if you are in doubt about it just follow the [working guide](WORKING.md)

## Hardware setup
Raspberry-noaa runs on Raspberry PI 2 and up. See the [hardware notes](HARDWARE.md)
