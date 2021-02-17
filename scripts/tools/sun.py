#!/usr/bin/env python3
import envbash
import ephem
import time
import sys
import os
from envbash import load_envbash

# load bash environment vars
load_envbash('/home/pi/.noaa-v2.conf')
tz_offset = int(os.environ['TZ_OFFSET'])
lat = str(os.environ['LAT'])
lon = str(os.environ['LON'])

timezone = tz_offset + time.localtime().tm_isdst
date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(int(sys.argv[1])-(timezone*60*60)))

obs=ephem.Observer()
obs.lat = lat
obs.long = lon
obs.date = date

sun = ephem.Sun(obs)
sun.compute(obs)
sun_angle = float(sun.alt) * 57.2957795 # Rad to deg

print(int(sun_angle))
