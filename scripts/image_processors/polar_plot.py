#!/usr/bin/env python3
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
#   8. Satellite direction of travel
#   9. Output filename
#  10. Type of plot ('azel' for Azimuth/Elevation or 'direction' for Directional)
#
# Example:
#   ./scripts/tools/polar_plot.py "NOAA 15" \
#                                 "/home/{{ target_user }}/raspberry-noaa-v2/tmp/orbit.tle" \
#                                 102394157 \
#                                 102394167 \
#                                 40.712776 \
#                                 -74.005974 \
#                                 30 \
#                                 Northbound \
#                                 "/tmp/test.png" \
#                                 azel

import datetime
import ephem
import matplotlib.pyplot as plt
import numpy as np
import sys
import time
import matplotlib.ticker as mticker
from math import degrees

def genPlotTitle(plot_type, pass_start_ms, sat, max_elev, direction):
  '''
  Generate and return a title to be overlaid on the polar plot
  '''
  start_datetime = datetime.datetime.fromtimestamp(pass_start_ms)
  plot_title =  "{}\n".format(plot_type)
  plot_title += "{}\n".format(sat.name)
  plot_title += "{}\n".format(start_datetime.strftime('%m/%d/%Y @ %H:%M:%S'))
  plot_title += "{:.0f}° Max Elevation\n".format(max_elev)
  plot_title += "{}".format(direction)

  return plot_title

def constructDirectionPlot(pass_start_ms, azimuth_pos, elevation_pos, sat, sat_min_elev, direction, out_file):
  '''
  Generate a pass direction polar plot given the elevation and azimuth coordinates
  '''
  # find the max elevation and coordinates
  # TODO: DRY up code with other function
  max_elev_pos = elevation_pos.index(max(elevation_pos))
  max_elev = elevation_pos[max_elev_pos]
  az_at_max_elev = np.deg2rad(azimuth_pos)[max_elev_pos]

  # capture AOS/LOS based on satellite minimum elevation
  aos_index = next(x for x,val in enumerate(elevation_pos) if val > sat_min_elev)
  aos_az = np.deg2rad(azimuth_pos)[aos_index]
  aos_el = np.array(elevation_pos)[aos_index]

  los_index = len(elevation_pos) - next(x for x,val in enumerate(elevation_pos, start=aos_index) if val < sat_min_elev)
  los_az = np.deg2rad(azimuth_pos)[los_index]
  los_el = np.array(elevation_pos)[los_index]

  # start to construct the title for the plot
  graph_title = genPlotTitle('Direction', pass_start_ms, sat, max_elev, direction)

  # create a polar plot of the direction of travel
  p = plt.subplot(111, projection='polar')
  p.set_theta_zero_location('N')
  p.set_theta_direction(-1)
  p.set_rlim(90, 0)
  p.set_yticks(np.arange(90, 0, step=-15))
  p.set_yticklabels(np.arange(90, 0, step=-15))
  ticks_loc = p.get_xticks().tolist()
  p.xaxis.set_major_locator(mticker.FixedLocator(ticks_loc))
  p.set_xticklabels(['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'])
  p.plot(np.deg2rad(azimuth_pos), np.array(elevation_pos))
  p.annotate(graph_title, xy=(0.02, 0.83), xycoords='figure fraction')

  # TODO: calculate and plot AOS/LOS and location and value of max elevation
  p.plot(aos_az, aos_el, 'g', marker="P", markersize=12, label="AOS")
  p.plot(los_az, los_el, 'r', marker="X", markersize=12, label="LOS")
  p.plot(az_at_max_elev, max_elev, 'o', marker="*", markersize=12, label="Max El")
  p.text(az_at_max_elev, max_elev-7, '{:.0f}°'.format(max_elev), fontweight="bold")

  p.legend(loc="lower left", bbox_to_anchor=(-0.38, -0.14))

  # save the file
  plt.savefig(out_file)

def constructAzElPlot(pass_start_ms, azimuth_pos, elevation_pos, sat, direction, out_file):
  '''
  Generate an azimuth/elevation polar plot given the elevation and azimuth coordinates
  '''
  # find the max elevation and coordinates
  # TODO: DRY up code with other function
  max_elev_pos = elevation_pos.index(max(elevation_pos))
  max_elev = elevation_pos[max_elev_pos]
  az_at_max_elev = np.deg2rad(azimuth_pos)[max_elev_pos]

  # start to construct the title for the plot
  graph_title = genPlotTitle('Azimuth/Elevation', pass_start_ms, sat, max_elev, direction)

  # create a polar plot of the azimuth and elevation
  p = plt.subplot(111, projection='polar')
  p.set_theta_zero_location('N')
  p.set_rlim(0, 92)
  p.set_theta_direction(-1)
  p.plot(np.deg2rad(azimuth_pos), np.array(elevation_pos))
  p.annotate(graph_title, xy=(0.02, 0.83), xycoords='figure fraction')

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

def displayUsage():
  print("Usage: ./polar_plot.py <satellite_name> \\")
  print("                       <tle_file> \\")
  print("                       <pass_start_ms> \\")
  print("                       <pass_end_ms> \\")
  print("                       <ground_station_latitude> \\")
  print("                       <ground_station_longitude> \\")
  print("                       <satellite_min_elevation> \\")
  print("                       <output_image_file> \\")
  print("                       <plot_type>")
  print("Where 'plot_type' is one of 'azel' (azimuth/elevation) or 'direction' (pass direction)")
  exit(1)

def main():
  '''
  Main function to check for usage, accept arguments from command
  line, and render the polar plot
  '''
  
  # parse input arguments
  if len(sys.argv) != 11:
    displayUsage()

  # TODO: This likely needs some input validation eventually
  satellite = sys.argv[1]
  tle_file = sys.argv[2]
  start_ms = int(sys.argv[3])
  end_ms = int(sys.argv[4])
  gs_latitude = sys.argv[5]
  gs_longitude = sys.argv[6]
  sat_min_elev = float(sys.argv[7])
  sat_direction = sys.argv[8]
  out_file = sys.argv[9]
  plot_type = sys.argv[10]

  # make sure one of two types is specified
  if plot_type != "azel" and plot_type != "direction":
    displayUsage()
  
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
  for dt in range(0, (end_ms - start_ms)):
    gs.date = datetime.datetime.utcfromtimestamp(start_ms + dt)
    sat.compute(gs)

    # only want to capture values for azimuth/elevation graph that
    # are above satellite minimum elevation
    if degrees(sat.alt) > sat_min_elev and plot_type == "azel":
      azimuth_pos.append(degrees(sat.az))
      elevation_pos.append(degrees(sat.alt))
    else:
      azimuth_pos.append(degrees(sat.az))
      elevation_pos.append(degrees(sat.alt))

  # calculate and construct the desired plot
  if plot_type == "azel":
    constructAzElPlot(start_ms, azimuth_pos, elevation_pos, sat, sat_direction, out_file)
  elif plot_type == "direction":
    constructDirectionPlot(start_ms, azimuth_pos, elevation_pos, sat, sat_min_elev, sat_direction, out_file)

if __name__ == '__main__':
  main()
