![Raspberry NOAA](../assets/header_1600_v2.png)

This project now includes full reception and decoding of SSTV transmissions from the ISS.

# ISS Reception and Scheduling

Reception is quite easy: the ISS TX works on 145.800 Mhz, Narrow FM. So we just need to tune our RTLSDR receiver and that's all.

Scheduling is governed by the `SCHEDULE_ISS` inside `.noaa.conf`. Setting it to `true` will schedule future ISS passes.

# ISS Decoding

This is the difficult part: decoding PD120 needs custom software. Right now the best Linux software for SSTV is
[QSSTV](http://users.telenet.be/on4qz/qsstv/index.html). QSSTV is great, works with a lot of modes, has auto slant and signal
detection. On the other hand, QSSTV only works in GUI mode as it's written in QT (hence Q-SSTV) and that's not situable for this
project as we don't run any X Server.

Through some web research, Martin Bernardi's (and team)
[final work about a PD120 modulator - demodulator](https://github.com/martinber/rtlsdr_sstv) proved promising, so Nico developed
a modification of the original work to suit this framework.

## Decoding Behavior

There are a few things to account for:

1. A single ISS pass during a SSTV event could have zero to three SSTV transmissions (based on an average pass time of 10 minutes)
so we need to find a way to detect the transmission header to fire up the decoder and store each image.

![PD 120 header](../assets/pd120_header.png)

2. A simple way to detect the header on an audio file (once digitized with scipy.io) is to sample the header as an absolute
numeric representation, apply a threshold during certain amount of time. So if the header is present, mark the stream and do
the same for each new header that ocurrs in about `this_timestamp + 120 seconds` so we don't get any false positives in the
middle of the PD120 carrier.

3. A Satellite transmission to the earth has doppler effect so the frequency changes over the time. This is a problem when you plot
audio as data. A high pass filter is included to remove the DC offset from the audio recorded by `rtl_fm`.
