#! /bin/bash

t="$*"

# validate
grep -Pqx '( *\d+[smhd])+ *' <<< "$t" || exit 1

# helper functions
sumAndMultiply() { bc <<< "(0$(paste -s -d+))*$1"; }
xToSeconds() { grep -Po "\\d+(?=$1)" | sumAndMultiply "$2"; }

# convert to seconds
(
        xToSeconds s 1 <<< "$t";
        xToSeconds m 60 <<< "$t";
        xToSeconds h 3600 <<< "$t";
        xToSeconds d 86400 <<< "$t";
) | sumAndMultiply 1
