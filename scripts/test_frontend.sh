#!/bin/bash

# Dependencies
sudo apt update
sudo apt install -y libsctp-dev build-essential make

cd ~

git clone https://j0lama:0b1fe6bbb294fd9d4462f0ac798880d82250d6a8@github.com/j0lama/CoreKube.git

cd CoreKube/
make
./corekube_frontend 192.168.4.80 192.168.4.78