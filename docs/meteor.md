![Raspberry NOAA](../assets/header_1600_v2.png)

# Meteor M2 Decoding

The Meteor M2 satellite uses a 72k QPSK 120hz carrier to send very high quality images.

# Receiving

Currently, the satellite is using 137.1Mhz as the center frequency, Wide-FM @ 120Khz. 


Historically this framework uses `rtl_fm` @ 288k and `sox` to capture the raw stream. Most likely, the 288k bandwidth may be lower.

More recently we have moved the framework to `gnuradio` mode to capture the raw stream. 
While at first the model still only works with RTL-SDR cards, this change of default to gnuradio is done to enable developers to work to introduce hardware SDR other than RTL-SDR and hopefully introduce them back to the repoistory and share new hardware options.


## gnuradio Decoding Steps
1. Capture the signal using `.py` scripts that were initially designed from the `.grc` [gnuradio](https://github.com/gnuradio/gnuradio) workflows included in the [audio_processors](https://github.com/jekhokie/raspberry-noaa-v2/tree/aug21-merging-gnuradio/scripts/audio_processors) folder in this repository, and then exported to python, manually modified to work with the Raspberry NOAA V2 variables. The `.py` scripts capture the signal from the hardware and produce a `.s` file (an experitmental format very similar to .qpsk.)
2. Use artlav's [medet_arm](https://github.com/artlav/meteor_decoder) to generate a rectified decoded .bmp for each sensor from the .s 
3. Use Imagemagik to conver and merge the files to produce output .bmps

There is more info here: Gnuradio workflow [README](https://github.com/jekhokie/raspberry-noaa-v2/tree/aug21-merging-gnuradio/scripts/audio_processors#readme)

## rtl_fm Decoding Steps

Below are the steps used to decode the signal:

1. Normalize audio stream with `sox gain -n`
2. Use dbdexter's [meteor_demod](https://github.com/dbdexter-dev/meteor_demod) to convert the audio stream to QPSK symbols at a 72k rate
3. Use artlav's [medet_arm](https://github.com/artlav/meteor_decoder) to generate a decoded dump and then a false color image
4. Use dbdexter's [meteor_rectify](https://github.com/dbdexter-dev/meteor_rectify) to correct the visible deformation on Meteor images (wrong aspect ratio)
   1. [Some changes](../scripts/rectify.py) were made to rectify to export to compressed JPG and remove some prints

