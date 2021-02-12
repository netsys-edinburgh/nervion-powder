#!/bin/bash

echo "Installing Linux Kernel 5.0.0-23-generic..."
  
sudo apt update
sudo apt -y install git build-essential strace net-tools iputils-ping iproute2 make cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
sudo apt -y install linux-image-5.0.0-23-generic linux-modules-5.0.0-23-generic linux-headers-5.0.0-23-generic
sudo grub-set-default 1
sudo update-grub

sudo reboot