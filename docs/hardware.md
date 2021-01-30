![Raspberry NOAA](../assets/header_1600_v2.png)

*(Notes below are from the original author, Nico...)*

# Raspberry PI

I tried to use a Raspberry PI Zero Wifi, but seems like the lack of power makes bananas. Got several issues when recording the audio
stream (blank audio, corrupted wav files, etc) as well as wxmap errors when trying to do the overlay. A Raspberry PI 2+ works great,
no issues at all.

# Power

I also experimented several issues with power supply when using cheap mobile phone USB chargers:

```
kern  :crit  : [ 1701.464833 <    2.116656>] Under-voltage detected! (0x00050005)
kern  :info  : [ 1707.668180 <    6.203347>] Voltage normalised (0x00000000)
```

Use a 2+ amps power supply, as the SDR dongle is a power demand device.

# SD Card

I'm using a cheap (and probably fake) 16GB Kingston SD card, no reported issues.

# SDR Dongle and reception

I'm using a rtl-sdr.com usb dongle, works great. I'm also using a FM trap (88-108Mhz) to avoid FM broadcast signals.

# Antenna

I'm using a homemade QFH antenna. Refer to [Jcoppens QFH antenna website](http://jcoppens.com/ant/qfh/index.en.php) for building
and calculations.
