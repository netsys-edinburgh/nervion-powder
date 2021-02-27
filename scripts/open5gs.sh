#!/bin/bash

echo "Installing Open5GS"
sudo apt update
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt install open5gs

echo "Installing webUI"
sudo apt -y install curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt -y install nodejs
curl -sL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

# Installing populator script dependencies
sudo apt -y install python3-pip
pip3 install pymongo

echo "Adding subscribers to the DB..."
cd /local/repository/scripts
python3 populate_open5gs_db.py 2048

echo "Modifying configuration files..."
sudo cp /local/repository/config/open5gs/amf.yaml /etc/open5gs/
sudo cp /local/repository/config/open5gs/upf.yaml /etc/open5gs/

echo "Restarting Open5GS..."
sudo systemctl restart open5gs-mmed
sudo systemctl restart open5gs-sgwcd
sudo systemctl restart open5gs-smfd
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-sgwud
sudo systemctl restart open5gs-upfd
sudo systemctl restart open5gs-hssd
sudo systemctl restart open5gs-pcrfd
sudo systemctl restart open5gs-nrfd
sudo systemctl restart open5gs-ausfd
sudo systemctl restart open5gs-udmd
sudo systemctl restart open5gs-pcfd
sudo systemctl restart open5gs-udrd
sudo systemctl restart open5gs-webui

echo "Done!"