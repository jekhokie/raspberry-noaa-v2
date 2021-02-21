#!/bin/bash
#
# Purpose: Add annotation text inline with image for a METEOR capture and writes file
#          to specified output image file.
#
# Input parameters:
#   1. Input .jpg file
#   2. Output .jpg file
#   3. Image quality percent (whole number)
#
# Example:
#   ./meteor_normalize_annotate.sh /path/to/inputfile.jpg /path/to/outputfile.jpg

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# input params
INPUT_JPG=$1
OUTPUT_JPG=$2
QUALITY=$3

# get the base config and append vars as needed
yml_config=$(cat "${NOAA_HOME}/config/settings.yml")
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_name: '$SAT_NAME'\n.../")                   # sat_name
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/capture_start: '$START_DATE'\n.../")            # capture_start
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/enhancement: '$ENHANCEMENT'\n.../")             # enhancement
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sat_max_elevation: '$SAT_MAX_ELEVATION'\n.../") # sat_max_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/sun_elevation: '$SUN_ELEV'\n.../")              # sun_elevation
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/pass_direction: $PASS_DIRECTION\n.../")         # pass_direction

# vars for image manipulation
tmp_dir="${NOAA_HOME}/tmp/annotation"
rendered_file="${tmp_dir}/index.html"

# generate annotation html and copy any assets
$SCRIPTS_DIR/tools/jinja2_to_file.py "${NOAA_HOME}/config/annotation/annotation.html.j2" "${yml_config}" "${rendered_file}"
find $NOAA_HOME/config/annotation/* -type f -not -name "*.j2" -exec cp {} "${tmp_dir}/" \;

# generate annotation png and crop to content
$WKHTMLTOIMG --enable-local-file-access --format png --quality 100 --transparent "file://${rendered_file}" "${tmp_dir}/annotation.png"
$CONVERT -format png "${tmp_dir}/annotation.png" -background none -flatten -trim +repage "${tmp_dir}/annotation.png"

# generate final image with annotation, doubling the annotation for account
# for the LRPT image sizes, keeping aspect ratio for original image
img_w=$($CONVERT "${tmp_dir}/annotation.png" -format "%w" info:)
img_h=$($CONVERT "${tmp_dir}/annotation.png" -format "%h" info:)
new_img_w=$((img_w * 2))
new_img_h=$((img_h * 2))
echo $new_img_w
echo $new_img_h
$CONVERT -format jpg "${INPUT_JPG}" \( "${tmp_dir}/annotation.png" -resize "${new_img_w}x${new_img_h}^" \) \
         -gravity $IMAGE_ANNOTATION_LOCATION \
         -geometry +10+10 \
         -composite "${OUTPUT_JPG}"
