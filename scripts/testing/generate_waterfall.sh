#!/bin/bash

[ $# -lt 1 ] && echo "usage: $0 inputfile" && exit -1

infile=$1
outfile=$1.png

echo "generating $outfile from $infile.
This may take a while, maybe get a coffee?"
./heatmap.py --ytick 60m $infile $outfile
