#!/bin/bash

# Dependencies
sudo apt install -y libsctp-dev build-essential make

git clone https://f2729a3624166a650d8a7027f62beaac525a11c0@github.com/j0lama/CoreKube.git

cd CoreKube/
make
./corekube_frontend 192.168.4.80 192.168.4.78