#!/bin/bash
#
# Purpose: Produce a histogram for a given input file and specified output file.
#
# Input parameters:
#   1. Input any image format
#   2. Desired output any image format
#   3. Title for the produced histogram chart
#   4. Additional comment (lower left) for the histogram chart
#
# Example:
#   ./histogram.sh /path/to/inputfile.jpg /path/to/outputfile.jpg "my chart title" "my chart comment"

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

# change input params to sane names for readability
IN_FILE=$1
OUT_FILE=$2
CHART_TITLE=$3
CHART_COMMENT=$4

# do some file/extension extraction and temp file variable creation
# to be used for cleaning up gmic output
input_file=$(basename "${IN_FILE}")
input_path=$(dirname "${IN_FILE}")
input_filename="${input_file%.*}"
input_fileext="${input_file##*.}"

os_release=$(cat /etc/os-release | grep -E "^DEBIAN_CODENAME|^VERSION_CODENAME" | awk -F"=" '{print $NF}' | sort | head -1)

#adjust output with os release
if [[ "${os_release}" == "bullseye" || "${os_release}" == "bookworm" ]];
then
   gmic_temp_1="${input_path}/_${input_filename}_c1.${input_fileext}"
else
   gmic_temp_1="${input_path}/_${input_filename}~.${input_fileext}"
fi

gmic_temp_2="${input_path}/_${input_file}"

# produce the histogram on a pristine image
$GMIC "${IN_FILE}" +histogram 256 display_graph[-1] 400,300,1,0,255,0 outputp
$CONVERT "${gmic_temp_1}" "${OUT_FILE}"
rm "${gmic_temp_1}"
rm "${gmic_temp_2}"
$CONVERT "${OUT_FILE}" -undercolor grey85 -fill black -pointsize 12 -annotate +5+12  "${CHART_TITLE}" "${OUT_FILE}"
$CONVERT "${OUT_FILE}" -gravity SouthWest -undercolor grey85 -fill black -pointsize 12 -annotate +5+1 "${CHART_COMMENT}" "${OUT_FILE}"
