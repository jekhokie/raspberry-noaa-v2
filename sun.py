#!/usr/bin/env python3
import ephem
import time
import sys

date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(int(sys.argv[1])+3*60*60))

obs=ephem.Observer()
obs.lat='change_latitude'
obs.long='change_longitude'
obs.date = date

sun = ephem.Sun(obs)
sun.compute(obs)
sun_angle = float(sun.alt) * 57.2957795 # Rad to deg
print(int(sun_angle))
