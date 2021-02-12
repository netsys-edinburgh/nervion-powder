#!/bin/bash

cd ~

#Install GTP Kernel module
echo "Installing 5G GTP Kernel module..."
git clone https://github.com/PrinzOwO/gtp5g.git
cd gtp5g
make clean && make
sudo make install
cd ..

# Install GO
echo "Installing GO..."
wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
sudo tar -C /usr/local -zxvf go1.14.4.linux-amd64.tar.gz
mkdir -p ~/go/{bin,pkg,src}
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export PATH=$PATH:$GOPATH/bin:$GOROOT/bin
go get -u github.com/sirupsen/logrus

# Install mongoDB
echo "Installing MongoDB..."
sudo apt -y install mongodb
sudo systemctl start mongodb

# Install Free5GCore
echo "Installing free5GC"
git clone --recursive -b v3.0.5 -j `nproc` https://github.com/free5gc/free5gc.git
cd free5gc/
make
chmod +x test.sh

# Compile webconsole
echo "Compiling free5GC webconsole..."
sudo apt -y remove cmdtest
sudo apt -y remove yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y nodejs yarn
make webconsole

# Modify configuration files
echo "Modifiying configuration files..."
sudo sed -i 's/- 127.0.0.1/- 192.168.4.80/g' config/amfcfg.yaml

# Add users to the DB
sudo apt -y install python3-pip
pip3 install pymongo
cd /local/repository/scripts
# Populate DB
echo "Populating DB..."
python3 populate_free5gc_db.py 1024