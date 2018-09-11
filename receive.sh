#!/bin/bash
if pgrep "rtl_fm" > /dev/null
then
	exit 1
fi
# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = EPOC start time
# $6 = Time to capture
start=`date '+%d-%m-%Y %H:%M'`
timeout $6 rtl_fm -f ${2}M -s 60k -g 50 -p 55 -E wav -E deemp -F 9 - | sox -t raw -e signed -c 1 -b 16 -r 60000 - /home/pi/audio/$3.wav rate 11025

PassStart=`expr $5 + 90`
/usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -o $PassStart /home/pi/map/${3}-map.png
for i in ZA MCIR MCIR-precip MSA MSA-precip HVC-precip HVCT-precip HVC HVCT; do
	/usr/local/bin/wxtoimg -o -m /home/pi/map/${3}-map.png -e $i /home/pi/audio/$3.wav /home/pi/image/$3-$i.png
	/usr/bin/convert /home/pi/image/$3-$i.png -undercolor black -fill yellow -pointsize 18 -annotate +20+20 "$1 $start" /home/pi/image/$3-$i.png
done
