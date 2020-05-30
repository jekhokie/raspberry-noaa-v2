![Raspberry NOAA](header.png)

### Meteor M2 decoding
The satellite uses a 72k QPSK 120hz carrier to send very high quality images

## Receiving
Currently, the satellite is using 137.1Mhz as the center frequency, Wide-FM @ 120Khz. I'm using `rtl_fm` @ 288k and `sox` to capture the raw stream. Most likely, the 288k bandwidth may be lower

## Decoding steps
1. Normalize audio stream with `sox gain -n`
2. Use dbdexter's [meteor_demod](https://github.com/dbdexter-dev/meteor_demod) to convert the audio stream to QPSK symbols at a 72k rate
3. Use artlav's [medet_arm](https://github.com/artlav/meteor_decoder) to generate a decoded dump and then a false color image
4. Use dbdexter's [meteor_rectify](https://github.com/dbdexter-dev/meteor_rectify) to correct the visible deformation on Meteor images (wrong aspect ratio)
   1. I made [some changes](rectify.py) to rectify to export to compressed JPG and remove some prints
