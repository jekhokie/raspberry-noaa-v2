#!/bin/bash

cd ~
sudo apt update
sudo apt install python3-dev python3-pip -y
sudo apt install cmake build-essential pkg-config git -y
sudo apt install libatlas-base-dev liblapacke-dev gfortran -y
sudo apt install libopencv-dev python3-opencv -y

git clone https://github.com/Digitelektro/MeteorDemod.git
cd MeteorDemod
git fetch --all
git checkout beta
git submodule update --init --recursive
mkdir build
cd build
cmake ../
make -j4
sudo make install
sudo chown $USER:$USER -R ~/.config/meteordemod

cd ~
