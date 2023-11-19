#!/bin/bash

set -e  # Exit on error
set -x  # Print each command

# Function to display an error message and exit
error_exit() {
    echo "SDRplay API install failed, please inspect the commands' outputs"
    exit 1
}

# Trap errors and call the error_exit function
trap 'error_exit' ERR

# Download and add the repository key
wget https://debian.hb9fxx.ch/debian/key.asc -O - | sudo apt-key add -

# Add the repository to sources.list.d
echo "deb https://debian.hb9fxx.ch/debian/ bullseye/" | sudo tee /etc/apt/sources.list.d/hb9fxx.list
echo "deb-src https://debian.hb9fxx.ch/debian/ bullseye/" | sudo tee -a /etc/apt/sources.list.d/hb9fxx.list

# Install required packages and update the package list
sudo apt update
sudo apt install -y apt-transport-https

# Install the libsdrplay-api package
sudo apt install -y libsdrplay-api

# Cleanup the repository file
#sudo rm /etc/apt/sources.list.d/hb9fxx.list            #Optional, not required

echo "SDRplay API has been successfully installed."
