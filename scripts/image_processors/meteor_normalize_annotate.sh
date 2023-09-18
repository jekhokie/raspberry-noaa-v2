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

# TODO: DRY this up - it's the same between meteor/noaa normalization scripts

# provide a long-form pass side
pass_side_long="West"
if [ "${PASS_SIDE}" == "E" ]; then
  pass_side_long="East"
fi

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
annotation="${tmp_dir}/annotation.png"

# generate annotation html and copy any assets
$SCRIPTS_DIR/tools/jinja2_to_file.py "${NOAA_HOME}/config/annotation/annotation.html.j2" "${yml_config}" "${rendered_file}"
find $NOAA_HOME/config/annotation/* -type f -not -name "*.j2" -exec cp {} "${tmp_dir}/" \;

# generate annotation png and crop to content
$WKHTMLTOIMG --enable-local-file-access --format png --quality 100 --transparent "file://${rendered_file}" "${annotation}"
$CONVERT -colorspace RGB -format png "${annotation}" -background none -flatten -trim +repage "${annotation}"

# resize the annotation appropriately, keeping aspect ratio
img_w=$($CONVERT "${annotation}" -format "%w" info:)
img_h=$($CONVERT "${annotation}" -format "%h" info:)
new_img_w=$((img_w * 2))
new_img_h=$((img_h * 2))
$CONVERT "${annotation}" -colorspace RGB -resize "${new_img_w}x${new_img_h}^" "${annotation}"

# extend the image if the user specified and didn't use
# one of [West|Center|East] for the annotation location
# TODO: DRY this up - this is the same code as in the NOAA script
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
  annotation_h=$($IDENTIFY -format "%h" "${annotation}")
  img_expand_px=$(($annotation_h + 20))
  out_file=$(basename $OUTPUT_JPG)
  tmp_out="${NOAA_HOME}/tmp/${out_file%%.*}-tmp.jpg"

  # create pixels north or south depending on annotation location
  gravity_var="South"
  if [[ "${annotation_location}" =~ ^(northwest|north|northeast)$ ]]; then
    gravity_var="North"
  fi

  $CONVERT -quality 100 -colorspace RGB \
           -format jpg "${INPUT_JPG}" \
           -gravity "${gravity_var}" \
           -background black \
           -splice "0x${img_expand_px}" "${tmp_out}"

  # clean up
  rm "${tmp_out}"
fi

# generate final image with annotation
$CONVERT -interlace Line -format jpg "${INPUT_JPG}" "${annotation}" -colorspace RGB \
          -gravity $IMAGE_ANNOTATION_LOCATION \
          -geometry +10+10 \
          -composite "${OUTPUT_JPG}"


# clean up the annotation
rm "${annotation}"
