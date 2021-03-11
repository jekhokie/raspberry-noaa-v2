#!/bin/bash

# import common lib and settings
. "$HOME/.noaa-v2.conf"
. "$NOAA_HOME/scripts/common.sh"

if [ -z "$1" ]; then
    log "Usage: $0 <frequency>. Example: $0 90.3" "ERROR"
    exit 1
fi

command_exists() {
    if ! command -v "$1" &> /dev/null; then
        log "Required command not found: $1" "ERROR"
        exit 1
    fi
}

command_exists "sox"
command_exists "socat"

IP=$(ip route | grep "link src" | awk {'print $NF'})

if pgrep "rtl_fm" > /dev/null
then
    log "There is an existing rtl_fm instance running, I quit" "ERROR"
    exit 1
fi

echo "$(tput setaf 2)
    The server is in testing mode tuned to $1 Mhz!
    Open a terminal in your computer and paste:
    ncat $IP 8073 | play -t mp3 -
    $(tput sgr0)
"

rtl_fm ${TEST_ENABLE_BIAS_TEE} -f "$1M" -s 256k -g $TEST_GAIN -p $TEST_FREQ_OFFSET -E deemp -F 9 - \
        | sox -traw -r256k -es -b16 -c1 -V1 - -tmp3 - \
        | socat -u - TCP-LISTEN:8073 1>/dev/null
