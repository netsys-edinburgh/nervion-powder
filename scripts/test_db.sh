#!/bin/bash

# Dependencies
sudo apt update
sudo apt install -y libconfig-dev build-essential make

cd ~

git clone https://j0lama:37962f1338ebfbfad0184e289106a000adcf00bb@github.com/j0lama/CoreKube.git

cd CoreKubeDB/
make
# Modify configuration file
sudo sed -i 's/127.0.0.1/192.168.4.79/g' db.conf
# TODO: Modify DB
./corekubeDB