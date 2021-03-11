#!/usr/bin/env bash
#
# Purpose: Simulate an annotation using example data that would normally be passed
#          as part of the call to `jinja2_to_png.py` to produce an annotation image
#          for overlay on top of capture images.
#
# Inputs:
#    1. Output file to store the image to
#
# Example:
#   ./produce_annotation_image.sh /tmp/output.png

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# make sure an output file is specified
if [ -z "$1" ]; then
  log "Usage: ./produce_annotation_image.sh <output_png_file>" "ERROR"
  exit 1
fi

# input parameters
OUT_FILE=$1

# get the base config
yml_config=$(cat "${NOAA_HOME}/config/settings.yml")

# inject variables for additional use
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_name: 'NOAA 19'\n.../")                # sat_name
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/capture_start: '19-02-2021 19:42'\n.../")  # capture_start
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/enhancement: 'MVC'\n.../")                 # enhancement
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_max_elevation: '42'\n.../")            # sat_max_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sun_elevation: '56'\n.../")                # sun_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_direction: Northbound\n.../")         # pass_direction
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_side: 'E'\n.../")                     # pass_side
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_side_long: 'East'\n.../")             # pass_side_long
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/gain: 40.2\n.../")                         # gain

# render j2 to file
tmp_dir="${NOAA_HOME}/tmp/annotation"
rendered_file="${tmp_dir}/index.html"
$NOAA_HOME/scripts/tools/jinja2_to_file.py $NOAA_HOME/config/annotation/annotation.html.j2 "${yml_config}" $rendered_file
if [ $? -eq 0 ]; then
  log "Jinja2 to file success" "INFO"
else
  log "Something went wrong attempting to render jinja2 template to file - see logs above" "ERROR"
  exit 1
fi

# copy any images into tmp directory
find $NOAA_HOME/config/annotation/* -type f -not -name "*.j2" -exec cp {} "${tmp_dir}/" \;

# create an image out of the html file
$WKHTMLTOIMG --enable-local-file-access --format png --quality 100 --transparent "file://${rendered_file}" $OUT_FILE
if [ $? -eq 0 ]; then
  log "Intermediate PNG generated" "INFO"
else
  log "Something went wrong attempting to produce intermediate PNG file - see logs above" "ERROR"
  exit 1
fi

# remove intermediate files
rm -f "${tmp_dir}/*"

# create a transparent background for the image so it doesn't disrupt the capture image when inlaid
$CONVERT -format png $OUT_FILE -background none -flatten -trim +repage $OUT_FILE
if [ $? -eq 0 ]; then
  log "Final PNG with transparent background generated - see ${OUT_FILE} for results!" "INFO"
else
  log "Something went wrong attempting to produce final PNG file - see logs above" "ERROR"
  exit 1
fi
