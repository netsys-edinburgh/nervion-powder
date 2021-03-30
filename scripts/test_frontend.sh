#!/bin/bash

# Dependencies
sudo apt update
sudo apt install -y libsctp-dev build-essential make

cd ~

git clone https://j0lama:37962f1338ebfbfad0184e289106a000adcf00bb@github.com/j0lama/CoreKube.git

cd CoreKube/
make
./corekube_frontend 192.168.4.80 192.168.4.78