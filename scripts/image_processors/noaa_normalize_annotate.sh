#!/bin/bash
#
# Purpose: Reduce image size/quality and add annotation text inline with image
#          and writes file to specified output image file for a NOAA capture.
#
# Input parameters:
#   1. Input .jpg file
#   2. Output .jpg file
#   3. Image quality percent (whole number)
#
# Example:
#   ./noaa_normalize_annotate.sh /path/to/inputfile.jpg 95

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_JPG=$1
OUTPUT_JPG=$2
QUALITY=$3

# provide a long-form pass side
pass_side_long="West"
if [ "${PASS_SIDE}" == "E" ]; then
  pass_side_long="East"
fi

# get the base config and append vars as needed
yml_config=$(cat "${NOAA_HOME}/config/settings.yml")
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_name: '$SAT_NAME'\n.../")                   # sat_name
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/capture_start: '$START_DATE'\n.../")            # capture_start
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/enhancement: '$ENHANCEMENT'\n.../")             # enhancement
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_max_elevation: '$SAT_MAX_ELEVATION'\n.../") # sat_max_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sun_elevation: '$SUN_ELEV'\n.../")              # sun_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_direction: $PASS_DIRECTION\n.../")         # pass_direction
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_side: $PASS_SIDE\n.../")                   # pass_side
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_side_long: $pass_side_long\n.../")         # pass_side_long

# vars for image manipulation
tmp_dir="${NOAA_HOME}/tmp/annotation"
rendered_file="${tmp_dir}/index.html"

# generate annotation html and copy any assets
$SCRIPTS_DIR/tools/jinja2_to_file.py "${NOAA_HOME}/config/annotation/annotation.html.j2" "${yml_config}" "${rendered_file}"
find $NOAA_HOME/config/annotation/* -type f -not -name "*.j2" -exec cp {} "${tmp_dir}/" \;

# generate annotation png and crop to content
$WKHTMLTOIMG --enable-local-file-access --format png --quality 100 --transparent "file://${rendered_file}" "${tmp_dir}/annotation.png"
$CONVERT -format png "${tmp_dir}/annotation.png" -background none -flatten -trim +repage "${tmp_dir}/annotation.png"

# generate final image with annotation
$CONVERT -quality $QUALITY \
         -format jpg "${INPUT_JPG}" "${tmp_dir}/annotation.png" \
         -gravity $IMAGE_ANNOTATION_LOCATION \
         -geometry +10+10 \
         -composite "${OUTPUT_JPG}"
