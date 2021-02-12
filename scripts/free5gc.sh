#!/bin/bash

# check if the reboot flag file exists. 
# We created this file before rebooting.
if [ ! -f /var/run/resume-after-reboot ]; then
	echo "Installing Linux Kernel 5.0.0-23-generic..."
  
	sudo apt update
	sudo apt install git build-essential strace net-tools iputils-ping iproute2 make cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
	sudo apt install linux-image-5.0.0-23-generic linux-modules-5.0.0-23-generic linux-headers-5.0.0-23-generic
	sudo grub-set-default 1
	sudo update-grub

	# Preparation for reboot
	script="bash /reload_bash_shell.sh"
  
	# add this script to bash so it gets triggered immediately after reboot
	echo "$script" >> ~/.bashrc 
  
	# create a flag file to check if we are resuming from reboot.
	sudo touch /var/run/resume-after-reboot
  
	echo "Rebooting..."
	sudo reboot
  
else 
	echo "Resuming script after reboot.."
  
	# Remove the line that we added in bashrc
	sed -i '/bash/d' ~/.bashrc 
  
	# remove the temporary file that we created to check for reboot
	sudo rm -f /var/run/resume-after-reboot

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
	echo 'export GOPATH=$HOME/go' >> ~/.bashrc
	echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
	echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
	source ~/.bashrc
	go get -u github.com/sirupsen/logrus

	# Install mongoDB
	echo "Installing MongoDB..."
	sudo apt install mongodb
	sudo systemctl start mongodb

	# Install Free5GCore
	echo "Installing free5GC"
	git clone --recursive -b v3.0.5 -j `nproc` https://github.com/free5gc/free5gc.git
	cd free5gc/
	make
	chmod +x test.sh

	# Compile webconsole
	echo "Compiling free5GC webconsole..."
	sudo apt remove cmdtest
	sudo apt remove yarn
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	sudo apt-get update
	sudo apt-get install -y nodejs yarn
	make webconsole

	# Modify configuration files
	echo "Modifiying configuration files..."
	sudo sed -i 's/- 127.0.0.1/- 192.168.4.80/g' config/amfcfg.yaml

	# Add users to the DB
	sudo apt install python3-pip
	pip3 install pymongo
	cd /local/repository/scripts
	# Populate DB
	echo "Populating DB..."
	python3 populate_free5gc_db.py 1024
fi