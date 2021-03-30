#!/bin/bash

# Dependencies
sudo apt-get install -y libconfig-dev

git clone https://f2729a3624166a650d8a7027f62beaac525a11c0@github.com/j0lama/CoreKubeDB.git

cd CoreKubeDB/
make
# Modify configuration file
sudo sed -i 's/127.0.0.1/192.168.4.79/g' db.conf
# TODO: Modify DB
./corekubeDB