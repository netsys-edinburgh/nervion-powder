#!/bin/bash

#!/bin/bash
#set -u
#set -x

# Install dependencies
sudo apt update
sudo apt-get -y install software-properties-common
sudo add-apt-repository ppa:nextepc/nextepc
sudo apt-get update
# Install NextEPC
sudo apt-get -y install nextepc

# Install web interface
sudo apt-get -y install curl
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
curl -sL https://nextepc.org/static/webui/install | sudo -E bash -

# Install DB populator dependencies
sudo apt-get -y install python3-pip
pip3 install pymongo

# Patch NextEPC config files
cd /etc/nextepc/
# MME.CONF
sudo sed -i 's/mcc: 001/mcc: 208/g' mme.conf
sudo sed -i 's/mnc: 01/mnc: 93/g' mme.conf
sudo sed -i 's/mme_gid: 2/mme_gid: 4/g' mme.conf
sudo sed -i 's/tac: 12345/tac: 1/g' mme.conf
# PGW.CONF
sudo sed -i 's/addr: 45.45.0.1/addr: 172.16.0.1/g' pgw.conf
# SGW.CONF
sudo sed -i 's/gtpu:/gtpu:\n      addr: 192.168.4.80/g' sgw.conf

# NEXTEPC.CONF
sudo sed -i 's/mcc: 001/mcc: 208/g' nextepc.conf
sudo sed -i 's/mnc: 01/mnc: 93/g' nextepc.conf
sudo sed -i 's/mme_gid: 2/mme_gid: 4/g' nextepc.conf
sudo sed -i 's/tac: 12345/tac: 1/g' nextepc.conf
sudo sed -i 's/addr: 45.45.0.1/addr: 172.16.0.1/g' nextepc.conf
sudo sed '234i\
      addr: 192.168.4.80' test.txt
#sudo sed -i 's/gtpu:/gtpu:\n      addr: 192.168.4.80/g' nextepc.conf

# Restart EPC services
sudo systemctl restart nextepc-mmed
sudo systemctl restart nextepc-pgwd
sudo systemctl restart nextepc-sgwd
sudo systemctl restart nextepc-hssd
sudo systemctl restart nextepc-pcrfd