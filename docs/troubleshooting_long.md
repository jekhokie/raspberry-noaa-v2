It is assumed you have read the main troubleshooting document before getting here.

```./support.sh```

Has needed information for the state of your install.

There can be a few causes for long passes with no data. Normally its a break in the workflow between the antenna and wxtoimg. Hardware causes are loose connections or a bias tee that is not on. 

```rtl_fm -f 97.3e6 -M wbfm -s 200000 -r 48000 - | aplay -r 48000 -f S16_LE```

This will play FM 97.3 through the pi headphones to test hardware. You can change the part that is ```-f 97.3e6``` to a station that is strong near you.

`cd /srv/audio/noaa`
`ls -s`

will show you if the .wav files recorded have any content. A normal noaa pass is about 20K blocks. 

`rtl_test`

will driver connection with your rtl. The output should look like this:

```
Found 1 device(s):
  0:  Realtek, RTL2838UHIDIR, SN: 00000001
 
Using device 0: Generic RTL2832U OEM
Found Rafael Micro R820T tuner
Supported gain values (29): 0.0 0.9 1.4 2.7 3.7 7.7 8.7 12.5 14.4 15.7 16.6 19.7 20.7 22.9 25.4 28.0 29.7 32.8 33.8 36.4 37.2 38.6 40.2 42.1 43.4 43.9 44.5 48.0 49.6
[R82XX] PLL not locked!
Sampling at 2048000 S/s.

Info: This tool will continuously read from the device, and report if
samples get lost. If you observe no further output, everything is fine.

Reading samples in async mode...
Allocating 15 zero-copy buffers
lost at least 148 bytes
```

Type ctrl C to exit.

```nano /var/log/raspberry-noaa-v2/output.log```

will let you see the log of what was happening durring the pass.
Here is a sample output. No images means there is a break before the line that says Satellite: NOAA, so read the top section carfully. (If you get to the section where starts signal processing without errors then then you are normally fine.

```26-03-2021 07:56 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Starting rtl_fm record
INFO : Recording at 137.1000 MHz...
26-03-2021 07:56 /home/pi/raspberry-noaa-v2/scripts/audio_processors/noaa_record.sh INFO : Recording at 137.1000 MHz...
Found 2 device(s):
  0:  Realtek, RTL2838UHIDIR, SN: 00000001
  1:  Realtek, RTL2838UHIDIR, SN: 2

Using device 0: Generic RTL2832U OEM
Found Rafael Micro R820T tuner
Tuner gain set to 22.90 dB.
activated bias-T on GPIO PIN 0
Tuned to 137580000 Hz.
Oversampling input by: 32x.
Oversampling output by: 1x.
Buffer size: 4.27ms
Allocating 15 zero-copy buffers
Sampling at 1920000 S/s.
Output at 60000 Hz.
Signal caught, exiting!

User cancel, exiting...
26-03-2021 08:12 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Producing spectrogram
26-03-2021 08:12 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Producing pristine image
Satellite: NOAA
Status: signal processing............................
Gain: 14.1
Gain: 14.1
Gain: 1.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
26-03-2021 08:13 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Generating Data for Histogram
Satellite: NOAA
Status: signal processing............................
Satellite: NOAA
Status: signal processing............................
26-03-2021 08:13 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Producing histogram of NOAA pristine image channel A
[gmic]-0./ Start G'MIC interpreter.
[gmic]-0./ Input file '/home/pi/raspberry-noaa-v2/tmp/NOAA-19-20210326-075653-a.png' at position 0 (1 image 1040x1998x1x1).
[gmic]-1./ Compute histogram of image [0], using 256 levels in range [0%,100%].
[gmic]-1./ Render 400x300 graph plot from data of image [0].
[gmic]-2./ Output images [0,1] as their initial locations, prefixed by '_'.
[gmic]-2./ End G'MIC interpreter.
26-03-2021 08:13 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Producing polar graph of direction for pass
26-03-2021 08:13 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Bulding pass map
Satellite: NOAA 19
Pass Start: 2021-03-26 14:56:54 UTC
Pass Duration: 15:47
Elevation: 69
Azimuth: 103
Direction: southbound
..26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Decoding image
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement ZA to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  204k    0   981  100  203k   1338   277k --:--:-- --:--:-- --:--:--  278k^M100  204k    0   981  100  203k$
{"id": "825024867413786664", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 ZA 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id": "8$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement MCIR to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M 65  317k    0     0   65  208k      0   761k --:--:-- --:--:-- --:--:--  759k^M100  318k    0   989  100  317k$
{"id": "825024923323334707", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 MCIR 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id": $
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement MCIR-precip to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  321k    0  1017  100  320k   1112   350k --:--:-- --:--:-- --:--:--  351k^M100  321k    0  1017  100  320k$
{"id": "825024983759585330", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 MCIR-precip 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channe$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement MSA to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:14 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M 53  329k    0     0   53  176k      0   775k --:--:-- --:--:-- --:--:--  771k^M100  330k    0   985  100  329k$
{"id": "825025045293432902", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 MSA 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id": "$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement MSA-precip to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  331k    0     0  100  331k      0   550k --:--:-- --:--:-- --:--:--  549k^M100  332k    0  1013  100  331k$
{"id": "825025107919241217", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 MSA-precip 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement HVC-precip to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  275k    0  1013  100  274k   1221   331k --:--:-- --:--:-- --:--:--  332k
{"id": "825025171621675048", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 HVC-precip 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement HVCT-precip to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  264k    0  1017  100  263k   1186   307k --:--:-- --:--:-- --:--:--  308k
{"id": "825025230547714109", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 HVCT-precip 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channe$
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement HVC to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:15 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  274k    0   985  100  273k   1067   296k --:--:-- --:--:-- --:--:--  297k^M100  274k    0   985  100  273k$
{"id": "825025289431679028", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 HVC 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id": "$
Satellite: NOAA 19
Status: signal processing............................
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Extending image for annotation
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement HVCT to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  263k    0   989  100  262k   1060   281k --:--:-- --:--:-- --:--:--  281k^M100  263k    0   989  100  262k$
{"id": "825025349024612413", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 HVCT 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id": $
Satellite: NOAA 19
Status: signal processing............................
Gain: 14.1
Channel A: 2 (near infrared)
Channel B: 4 (thermal infrared)
Loading page (1/2)
[>                                                           ] 0%^M[======>                                                     ] 10%^M[==============================>                          $
[>                                                           ] 0%^M[===============>                                            ] 25%^M[=========================================================$
INFO : Overlaying thermal temperature gauge
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Overlaying thermal temperature gauge
INFO : Extending image for annotation
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/image_processors/noaa_normalize_annotate.sh INFO : Extending image for annotation
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Pushing image enhancement therm to Discord
INFO : Sending message to Discord webhook
26-03-2021 08:16 /home/pi/raspberry-noaa-v2/scripts/push_processors/push_discord.sh INFO : Sending message to Discord webhook
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
^M  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0^M100  232k    0   993  100  231k   1059   247k --:--:-- --:--:-- --:--:--  248k^M100  232k    0   993  100  231k$
{"id": "825025412324524134", "type": 0, "content": "Ground Station: Napa, CA\nNOAA 19 therm 26-03-2021 07:56 Max Elev: 68\u00b0 E Sun Elevation: 10\u00b0 Gain: 22.9 | Southbound", "channel_id":$
26-03-2021 08:56 /home/pi/raspberry-noaa-v2/scripts/receive_noaa.sh INFO : Starting rtl_fm record
```
