#!/bin/bash
set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
RESET=$(tput sgr0)

. "$HOME/.noaa.conf"

die() {
    >&2 echo "${RED}error: $1${RESET}" && exit 1
}

log_running() {
    echo " ${YELLOW}*${RESET} $1"
}


log_done() {
    echo "    ${GREEN}✓${RESET} $1"
}

log_error() {
    echo "    ${RED}error: $1${RESET}"
}

success() {
    echo "${GREEN}$1${RESET}"
}

### Run as a normal user
if [ $EUID -eq 0 ]; then
    die "This script shouldn't be run as root."
fi

# check to ensure TZ_OFFSET is added to noaa.conf
# which is needed since updating sun.py to be generic
# and use bash environment vars
log_running "Checking for TZ_OFFSET env var..."
if [[ -v TZ_OFFSET ]]; then
  log_done "TZ_OFFSET in place - all set"
else
  log_error "TZ_OFFSET is missing from /home/pi/.noaa.conf - please add."
fi

echo "All checks complete - please see above for details!"
