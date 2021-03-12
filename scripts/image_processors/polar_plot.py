#! /usr/bin/env python3
#
# Purpose: Create a polar plot of a satellite elevation and azimuth for a pass.
#
# Input parameters:
#   1. Satellite name
#   2. TLE file
#   3. Start datetime
#   4. End datetime
#   5. Ground station latitude
#   6. Ground station longitude
#   7. Satellite min elevation
#   8. Output filename
#
# Example:
#   ./scripts/tools/polar_plot.py "NOAA 15" \
#                                 "/home/pi/raspberry-noaa-v2/tmp/orbit.tle" \
#                                 102394157 \
#                                 102394167 \
#                                 40.712776 \
#                                 -74.005974 \
#                                 30 \
#                                 "/tmp/test.png"

import datetime
import ephem
import matplotlib.pyplot as plt
import numpy as np
import sys
import time
from math import degrees

def getSat(filename, sat_name):
  '''
  Load specific satellite TLE data from a file and return
  an ephem object (or NoneType if failure)
  '''
  f = open(filename)
  line1 = f.readline().strip()
  while line1:
    line2 = f.readline().strip()
    line3 = f.readline().strip()

    # check if we've found the satellite and, if so, return
    # the ephem object (or continue if not found)
    if line1 == sat_name:
      return ephem.readtle(line1, line2, line3)
    else:
      line1 = f.readline().strip()

  return None

def main():
  '''
  Main function to check for usage, accept arguments from command
  line, and render the polar plot
  '''
  
  # parse input arguments
  # TODO: This likely needs some input validation eventually
  satellite = sys.argv[1]
  tle_file = sys.argv[2]
  start_ms = int(sys.argv[3])
  end_ms = int(sys.argv[4])
  gs_latitude = sys.argv[5]
  gs_longitude = sys.argv[6]
  sat_min_elev = float(sys.argv[7])
  out_file = sys.argv[8]
  
  # establish ground station coordinates
  gs = ephem.Observer()
  gs.lat = gs_latitude
  gs.lon = gs_longitude
  gs.elevation = 0

  # load the TLE data
  sat = getSat(tle_file, satellite)
  if sat is None:
    print("Could not determine satellite {} using TLE file {}".format(satellite, tle_file))
    exit(1)
  
  # collect azimuth and elevation values
  azimuth_pos = []
  elevation_pos = []
  max_elevation = []
  delta_time = end_ms - start_ms
  for dt in range(0, delta_time):
    gs.date = datetime.datetime.utcfromtimestamp(start_ms + dt)
    sat.compute(gs)

    if degrees(sat.alt) > sat_min_elev:
      azimuth_pos.append(degrees(sat.az))
      elevation_pos.append(degrees(sat.alt))
  
  # find the max elevation and coordinates
  max_elev_pos = elevation_pos.index(max(elevation_pos))
  max_elev = elevation_pos[max_elev_pos]
  az_at_max_elev = np.deg2rad(azimuth_pos)[max_elev_pos]
  
  # start to construct the title for the plot
  start_datetime = datetime.datetime.fromtimestamp(start_ms)
  graph_title = "{}\n".format(sat.name)
  graph_title += "{}".format(start_datetime.strftime('%m/%d/%Y @ %H:%M:%S'))
  
  # create a polar plot of the azimuth and elevation
  p = plt.subplot(111, projection='polar')
  p.set_theta_zero_location('N')
  p.set_rlim(0, 92)
  p.set_theta_direction(-1)
  p.plot(np.deg2rad(azimuth_pos), np.array(elevation_pos))
  p.annotate(graph_title, xy=(0.02, 0.93), xycoords='figure fraction')
  
  # calculate and plot start and end points, as well
  # as location and value of max elevation
  start_az = np.deg2rad(azimuth_pos)[0]
  start_el = np.array(elevation_pos)[0]
  end_az = np.deg2rad(azimuth_pos)[len(azimuth_pos)-1]
  end_el = np.array(elevation_pos)[len(elevation_pos)-1]
  
  p.plot(start_az, start_el, 'g', marker="P", markersize=12)
  p.plot(end_az, end_el, 'r', marker="X", markersize=12)
  p.plot(az_at_max_elev, max_elev, 'o', marker="*", markersize=12)
  p.text(az_at_max_elev, max_elev-7, '{:.0f}°'.format(max_elev), fontweight="bold")
  
  # save the file
  plt.savefig(out_file)

if __name__ == '__main__':
  main()
