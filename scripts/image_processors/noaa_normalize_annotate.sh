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

# TODO: DRY this up - it's the same between meteor/noaa normalization scripts

# determine if auto-gain is set - handles "0" and "0.0" floats
gain=$GAIN
if [ $(echo "$GAIN==0"|bc) -eq 1 ]; then
  gain='Automatic'
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
yml_config=$(echo "${yml_config}" | sed -e "s/\.\.\.$/gain: $gain\n.../")                             # gain

# vars for image manipulation
tmp_dir="${NOAA_HOME}/tmp/annotation"
rendered_file="${tmp_dir}/index.html"

# generate annotation html and copy any assets
$SCRIPTS_DIR/tools/jinja2_to_file.py "${NOAA_HOME}/config/annotation/annotation.html.j2" "${yml_config}" "${rendered_file}"
find $NOAA_HOME/config/annotation/* -type f -not -name "*.j2" -exec cp {} "${tmp_dir}/" \;

# generate annotation png and crop to content
$WKHTMLTOIMG --enable-local-file-access --format png --quality 100 --transparent "file://${rendered_file}" "${tmp_dir}/annotation.png"
$CONVERT -format png -colorspace RGB "${tmp_dir}/annotation.png" -background none -flatten -trim +repage "${tmp_dir}/annotation.png"

# extend the image if the user specified and didn't use
# one of [West|Center|East] for the annotation location
annotation_location=$(echo $IMAGE_ANNOTATION_LOCATION | tr '[:upper:]' '[:lower:]')
extend_annotation=0
if [ "${EXTEND_FOR_ANNOTATION}" == "true" ]; then
  if [[ "${annotation_location}" =~ ^(west|center|east)$ ]]; then
    log "You specified extending the annotation, but your annotation location $annotation_location does not support it" "WARN"
  else
    extend_annotation=1
  fi
fi

# determine offset of annotation based on "expansion", and
# set up pipeline for input images
geometry="+10+10"
next_in="${INPUT_JPG}"

# generate image with thermal overlay (if specified)
if [ "${ENHANCEMENT}" == "therm" ] && [ "${NOAA_THERMAL_TEMP_OVERLAY}" == "true" ]; then
  log "Overlaying thermal temperature gauge" "INFO"
  $CONVERT -quality 100 -colorspace RGB \
           -format jpg "${next_in}" "${NOAA_HOME}/assets/thermal_gauge.png" \
           -gravity $NOAA_THERMAL_TEMP_OVERLAY_LOCATION \
           -geometry +10+10 \
           -composite "${OUTPUT_JPG}"
  next_in=$OUTPUT_JPG
fi

# extend the image if desired
if [ $extend_annotation -eq 1 ]; then
  log "Extending image for annotation" "INFO"
  geometry="+0+10"

  # calculate expansion height needed to fit annotation
  annotation_h=$($IDENTIFY -format "%h" "${tmp_dir}/annotation.png")
  img_expand_px=$(($annotation_h + 20))

  # create pixels north or south depending on annotation location
  gravity_var="South"
  if [[ "${annotation_location}" =~ ^(northwest|north|northeast)$ ]]; then
    gravity_var="North"
  fi

  $CONVERT -interlace Line -quality 100 -colorspace RGB \
           -format jpg "${next_in}" \
           -gravity "${gravity_var}" \
           -background black \
           -splice "0x${img_expand_px}" "${OUTPUT_JPG}"

  next_in=$OUTPUT_JPG
fi

# generate final image with annotation
$CONVERT -interlace Line -quality $QUALITY -colorspace RGB \
         -format jpg "${next_in}" "${tmp_dir}/annotation.png" \
         -gravity $IMAGE_ANNOTATION_LOCATION \
         -geometry $geometry \
         -composite "${OUTPUT_JPG}"
