![Raspberry NOAA](../assets/header_1600.png)

This project now includes full reception and decoding of SSTV transmissions from the ISS.

# ISS reception and scheduling
Reception is quite easy: The ISS TX works on 145.800 Mhz, Narrow FM. So we just need to tune our RTLSDR receiver and that's all.

Scheduling is governed by the `SCHEDULE_ISS` inside `.noaa.conf`. Setting it to `true` will schedule future ISS passes.

# ISS decoding
This is the difficult part: Decoding PD120 needs custom software. Right now the best Linux software for SSTV (in mu humble opinion) is [QSSTV](http://users.telenet.be/on4qz/qsstv/index.html). QSSTV is great, works with a lot of modes, has auto slant and signal detection. On the other hand, QSSTV only works in GUI mode as it's written in QT (hence Q-SSTV) and that's not situable for this project as we don't run any Window Server.

Surfing the Internet I've found Martin Bernardi's (and team) [final work about a PD120 modulator - demodulator](https://github.com/martinber/rtlsdr_sstv) so I put hands on slightly modifying it to adjust the project to my needs.

## Decoding behavior
There are a few things to take care about

1. A single ISS pass during a SSTV event could have zero to three SSTV transmissions (based on an average pass time of 10 minutes) so we need to find a way to detect the transmission header to fire up the decoder and store each image.

![PD 120 header](../assets/pd120_header.png)

2. A simple way to detect the header on an audio file (once digitized with scipy.io) is to sample the header as an absolute numeric representation, apply a threshold during certain amount of time. So if the header is present, mark the stream and do the same for each new header that ocurrs in about `this_timestamp + 120 seconds` so we don't get any false positives in the middle of the PD120 carrier.

3. A Satellite transmission to the earth has doppler efect so the frequency changes over the time. This is a problem when you plot audio as data. So I had to include a high pass filter to remove the DC offset from the audio recorded by `rtl_fm`.

# Upgrading procedure
There's a migration script that handles the required modifications over the database as well as the web files. Take in mind that you need to have the web panel version of raspberry-noaa-v2 running.

1. `cd /home/pi/raspberry-noaa-v2`
2. `git fetch -pt && git pull`
3. `cd migrations/`
4. `./20201292-iss.sh`
