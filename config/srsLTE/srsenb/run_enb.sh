#!/bin/bash

# Make cpu performance mode
governor="/local/repository/config/srsLTE/governor.sh"
sudo bash $governor

# Run srsLTE UE
enb_root="/usr/local/src/srsLTE/build/srsenb/src/"
enb_conf="/local/repository/config/srsLTE/srsenb/enb.conf"
cp $enb_conf $enb_root
(cd  $enb_root && sudo ./srsenb ./enb.conf)
