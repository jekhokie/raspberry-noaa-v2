![Raspberry NOAA](../assets/header_1600_v2.png)

# Hardware Cheat Sheet

This document details various hardware that has been tested and/or confirmed in use by users of this framework, as well
as known "non-working" models of hardware to help speed adoption of this framework for new users.

## Raspberry Pi

Below are Raspberry Pi models that are in use and confirmed working with this framework:

* Raspberry Pi 4 (2GB)
* Raspberry Pi 3 B+
* Raspberry Pi 3 B
* Raspberry Pi 2 B
* Raspberry Pi 2
* Raspberry Pi Zero W 2 (In testing) - Can not use desktop.

Below are Raspberry Pi models that have been tested but do *not* work with this framework:

* Raspberry Pi Zero WH: Tested, not working. Lacks sufficient power, resulting in audio recording and wxmap issues.

## Notes on Power

SDR dongles are power hungry and it's important to run a sufficient 2+ Amp power supply with your Pi device. Failure
to use a sufficient power source can result in erorr messages like below in your OS logs:

```
kern  :crit  : [ 1701.464833 <    2.116656>] Under-voltage detected! (0x00050005)
kern  :info  : [ 1707.668180 <    6.203347>] Voltage normalised (0x00000000)
```

## SD Card

Any SD card that is functional for a Raspberry Pi should work. Recommendation is to choose a reputable brand (not a knockoff)
and to choose the highest Class/U rating possible to enable faster write and read activity.

## SDR Dongle and reception

Below are links to SDR receivers that are in use and confirmed working with this framework:

* [RTL-SDR.com V3 Dongle](https://www.rtl-sdr.com/buy-rtl-sdr-dvb-t-dongles/)
* [Nooelec NESDR SMArTee XTR SDR](https://www.nooelec.com/store/nesdr-smartee-xtr-sdr.html)

## Antenna

Below are links to antennas and calculators that are in use and confirmed working with this framework:

Dipole:

* [Basic and Cheap Dipole Rabbit Ears](https://jekhokie.github.io/noaa/satellite/rf/antenna/sdr/2019/05/31/noaa-satellite-imagery-sdr.html)), working.

Quadrifilar (QFH) Antenna:

* [John Coppens QFH Calculator](http://jcoppens.com/ant/qfh/index.en.php)
* [Thingverse 3-Printed QFH](https://www.thingiverse.com/make:768284)
* [Tin Hat Ranch QFH](https://usradioguy.com/wp-content/uploads/2020/05/20200307-How-To-Build-A-QFH.pdf)

## Other Hardware

Below are links to other hardware that are in use and confirmed working with this framework or in general:

* [Nooelec SAWbird+ NOAA Filter](https://www.nooelec.com/store/sdr/sdr-addons/sawbird-plus-noaa-308.html)
* [Flamingo+ FM Notch Filter](https://www.nooelec.com/store/sdr/sdr-addons/flamingo-plus-fm.html)
* Double Cross Antenna
* RG-174u Cable
* S-LMR240 Cable
