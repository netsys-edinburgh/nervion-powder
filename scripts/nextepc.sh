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
sudo apt install python3-pip
pip3 install pymongo

# Patch NextEPC config files

# Restart EPC service