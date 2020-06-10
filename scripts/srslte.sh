#!/bin/bash
#set -u
#set -x

# Install dependencies
sudo apt-get update
sudo apt-get install -y cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev
cd ..
git clone https://github.com/srsLTE/srsLTE.git
cd srsLTE
mkdir build
cd build
cmake ../
make
sudo make install
cd ../../


sudo srsepc_if_masq.sh eno1
sudo srsepc /local/repository/config/srsepc/epc.conf