#!/bin/bash

# Dependencies
sudo apt update
sudo apt install -y libconfig-dev build-essential make

cd ~

git clone https://j0lama:0b1fe6bbb294fd9d4462f0ac798880d82250d6a8@github.com/j0lama/CoreKube.git

cd CoreKubeDB/
make
# Modify configuration file
sudo sed -i 's/127.0.0.1/192.168.4.79/g' db.conf
# TODO: Modify DB
./corekubeDB