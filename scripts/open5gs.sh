#!/bin/bash

# Update repository
echo "Updating repositories..."
sudo apt -y update

# Install MongoDB
echo "Installing MongoDB..."
sudo apt -y install mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb

# Configure TUN interface
echo "Configuring TUN interface..."
sudo ip tuntap add name ogstun mode tun
sudo ip addr add 172.16.0.1/16 dev ogstun
sudo ip addr add 2001:230:cafe::1/48 dev ogstun
sudo ip link set ogstun up

# Install dependencies
echo "Installing dependencies..."
sudo apt -y install python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev meson software-properties-common unzip

cd /local/repository/

# Download Open5GS 2.1.7
echo "Cloning Open5GS v2.1.7..."
wget https://github.com/open5gs/open5gs/archive/refs/tags/v2.1.7.zip
unzip v2.1.7.zip
mv open5gs-2.1.7/ open5gs/

# Compile Open5GS
echo "Compiling Open5GS..."
cd open5gs/
meson build --prefix=`pwd`/install
ninja -C build

sudo ldconfig

echo "Installing Open5GS..."
cd build
ninja install
cd ../

echo "Adding subscribers to the DB..."
for i in $(seq -f "%010g" 1 1500)
do
	echo "UE: 20893$i"
	/local/repository/open5gs/misc/db/open5gs-dbctl add 20893$i 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA
done

sudo /local/repository/open5gs/build/tests/app/5gc -c /local/repository/config/open5gs/sample.yaml &
