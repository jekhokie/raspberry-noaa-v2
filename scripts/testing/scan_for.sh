#!/bin/bash
#
# Purpose: Start a heatmap scan for a defined time
#
# Inputs:
#    1. Timeframe to perform the scan
#
# Example:
#   ./scan_for.sh 5h

[ $# -lt 1 ] && echo "usage: $0 time (e.g. 1s, 10m, 2h)" && exit -1
scriptpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
duration=$1
outfile=timed_scan_$(date  +"%d.%m.%y-%H.%M").csv.gz
outpath=$HOME/raspberry-noaa-v2/tmp/scanner

if ! [[ "$duration" =~ ^[0-9]+[s,m,h]*$ ]] ; then
  echo "
  Invalid parameter $duration.
  usage: $0 time (e.g. 1s, 10m, 2h)
  "
  exit -1
fi

startdate=$(date)
secs=$($scriptpath/t2sec.sh $duration)
echo ""
echo -n "     Starting at "
echo $startdate
echo -n "     Finishing at "
date --date "$start $secs sec"

echo "
$(tput setaf 2)
        Scanning for $duration, expect a $outfile.png in $outpath afterwards.
$(tput sgr0)"

$scriptpath/start_scanning.sh $outpath/$outfile
sleep 1
if ! pidof rtl_power >/dev/null ; then
  echo "
  $(tput setaf 2)
        Start of scan was not successful. Are any captures running?
  $(tput sgr0)"
  exit -1
fi

nohup &>/dev/null bash -c "sleep $duration; $scriptpath/stop_and_finalize_scanning.sh $outpath/$outfile" &
