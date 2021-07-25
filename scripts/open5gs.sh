#!/bin/bash

echo "Installing Open5GS"
sudo apt update
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:open5gs/latest
sudo apt update
sudo apt -y install open5gs=2.1.7

echo "Installing webUI"
sudo apt -y install curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt -y install nodejs
curl -sL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -

echo "Adding subscribers to the DB..."
for i in $(seq -f "%010g" 1 1500)
do
	echo "UE: 20893$i"
	open5gs-dbctl add 20893$i 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA
done

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