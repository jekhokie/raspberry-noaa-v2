# NOAA Automated capture using Raspberry PI
Most of the code and setup stolen from:  [Instructables](https://www.instructables.com/id/Raspberry-Pi-NOAA-Weather-Satellite-Receiver/)
### New Features!
  - Nginx webserver to show images
  - Timestamp and satellite name over every image
  - WXToIMG configured to create several images (HVC,HVCT,MCIR, etc)
  - Pictures are posted to Twitter. See more at [argentinasat twitter account](https://twitter.com/argentinasat)
  - [Wiki](https://github.com/reynico/raspberry-noaa/wiki) is updated!

### Manual work
  - sudo apt-get install imagemagick nginx predict libusb-1.0 cmake
  - Install [rtlsdr](https://github.com/keenerd/rtl-sdr.git) 

### Important notes
- I tried to run this on a Raspberry PI Zero Wifi, no luck. Seems like it's too much load for the CPU. Running on a Raspberry PI 2+ is ok.
- Code was a bit updated on how it handles the UTC vs timezone times.
