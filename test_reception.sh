#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <frequency>. Example: $0 90.3"
    exit 1
fi

command_exists() {
    if ! command -v "$1" &> /dev/null; then
        echo "Required command not found: $1"
        exit 1
    fi
}

command_exists "sox"
command_exists "socat"

## import common lib
. "$HOME/.noaa.conf"
. "$NOAA_HOME/common.sh"

IP=$(ip route | grep "link src" | awk {'print $NF'})

echo "$(tput setaf 2)
    The server is in testing mode tuned to $1 Mhz!
    Open a terminal in your computer and paste:
    ncat $IP 8073 | play -t mp3 -
    $(tput sgr0)
"

rtl_fm ${BIAS_TEE} -f "$1M" -s 256k -g 48 -p 55 -E deemp -F 9 - \
        | sox -traw -r256k -es -b16 -c1 -V1 - -tmp3 - \
        | socat -u - TCP-LISTEN:8073 1>/dev/null
