#!/bin/bash

[ $# -lt 1 ] && echo "usage: $0 inputfile" && exit -1

killall rtl_power
./generate_waterfall.sh $1
