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
$CONVERT -format png "${tmp_dir}/annotation.png" -background none -flatten -trim +repage "${tmp_dir}/annotation.png"

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

# generate the final image with annotation
if [ $extend_annotation -eq 1 ]; then
  # calculate expansion height needed to fit annotation
  annotation_h=$($IDENTIFY -format "%h" "${tmp_dir}/annotation.png")
  img_expand_px=$(($annotation_h + 20))
  out_file=$(basename $OUTPUT_JPG)
  tmp_out="${NOAA_HOME}/tmp/${out_file%%.*}-tmp.jpg"

  # create pixels north or south depending on annotation location
  gravity_var="South"
  if [[ "${annotation_location}" =~ ^(northwest|north|northeast)$ ]]; then
    gravity_var="North"
  fi

  $CONVERT -quality 100 \
           -format jpg "${INPUT_JPG}" \
           -gravity "${gravity_var}" \
           -background black \
           -splice "0x${img_expand_px}" "${tmp_out}"

  # generate image with thermal overlay (if specified)
  # TODO: DRY this up
  if [ "${ENHANCEMENT}" == "therm" ] && [ "${NOAA_THERMAL_TEMP_OVERLAY}" == "true" ]; then
    $CONVERT -quality 100 \
             -format jpg "${tmp_out}" "${NOAA_HOME}/assets/thermal_gauge.png" \
             -gravity $NOAA_THERMAL_TEMP_OVERLAY_LOCATION \
             -geometry +10+10 \
             -composite "${tmp_out}"
  fi

  # generate final image with annotation
  $CONVERT -quality $QUALITY \
           -format jpg "${tmp_out}" "${tmp_dir}/annotation.png" \
           -gravity $IMAGE_ANNOTATION_LOCATION \
           -geometry +0+10 \
           -composite "${OUTPUT_JPG}"

  # clean up
  rm "${tmp_out}"
else
  # generate image with thermal overlay (if specified)
  # TODO: DRY this up
  if [ "${ENHANCEMENT}" == "therm" ] && [ "${NOAA_THERMAL_TEMP_OVERLAY}" == "true" ]; then
    $CONVERT -quality 100 \
             -format jpg "${OUTPUT_JPG}" "${NOAA_HOME}/assets/thermal_gauge.png" \
             -gravity $NOAA_THERMAL_TEMP_OVERLAY_LOCATION \
             -geometry +10+10 \
             -composite "${OUTPUT_JPG}"
  fi

  # generate image with annotation
  $CONVERT -quality $QUALITY \
           -format jpg "${INPUT_JPG}" "${tmp_dir}/annotation.png" \
           -gravity $IMAGE_ANNOTATION_LOCATION \
           -geometry +10+10 \
           -composite "${OUTPUT_JPG}"
fi
