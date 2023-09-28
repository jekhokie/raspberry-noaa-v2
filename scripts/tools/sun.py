import envbash
import ephem
import time
import sys
import os
import subprocess  # Import the subprocess module

from envbash import load_envbash

# Use parameter expansion to expand ~ to the home folder
config_file = os.path.expanduser('~/.noaa-v2.conf')

# Load bash environment vars
load_envbash(config_file)

# Use subprocess to get the local time offset from UTC
timezone = int(subprocess.check_output('echo $(date "+%:::z") | sed "s/\\([+-]\\)0\\?/\\1/"', shell=True, text=True))

date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(int(sys.argv[1]) - (timezone * 60 * 60)))

lat = str(os.environ['LAT'])
lon = str(os.environ['LON'])

obs = ephem.Observer()
obs.lat = lat
obs.long = lon
obs.date = date

sun = ephem.Sun(obs)
sun.compute(obs)
sun_angle = float(sun.alt) * 57.2957795  # Rad to deg

print(int(sun_angle))
