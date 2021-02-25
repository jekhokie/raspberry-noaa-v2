#!/bin/bash

[ $# -lt 1 ] && echo "usage: $0 time (e.g. 1s, 10m, 2h)" && exit -1

duration=$1
outfile=timed_scan_$(date  +"%d.%m.%y-%H.%M").csv.gz

echo "
$(tput setaf 2)
        Scanning for $duration, output file is $outfile .
$(tput sgr0)"


./start_scanning.sh $outfile
nohup bash -c "sleep $duration; ./stop_and_finalize_scanning.sh $outfile" &
