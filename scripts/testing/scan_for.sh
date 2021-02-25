#!/bin/bash
# Purpose: Start a heatmap scan for a defined time

# Example:
#   ./scan_for.sh 5h

[ $# -lt 1 ] && echo "usage: $0 time (e.g. 1s, 10m, 2h)" && exit -1
scriptpath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
duration=$1
outfile=timed_scan_$(date  +"%d.%m.%y-%H.%M").csv.gz

echo "
$(tput setaf 2)
        Scanning for $duration, output file is $outfile .
$(tput sgr0)"


$scriptpath/start_scanning.sh $outfile
nohup bash -c "sleep $duration; $scriptpath/stop_and_finalize_scanning.sh $outfile" 2> /dev/null &
