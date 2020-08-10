#!/bin/bash

# Make cpu performance mode
governor="/local/repository/config/srsLTE/governor.sh"
sudo bash $governor

# Run srsLTE UE
ue_root="/usr/local/src/srsLTE/build/srsue/src"
ue_conf="/local/repository/config/srsLTE/srsue/ue.conf"
ue_ctxt="/usr/local/src/srsLTE/build/srsue/src/.ctxt"
sudo rm $ue_ctxt
cp $ue_conf $ue_root
(cd $ue_root && sudo ./srsue ./ue.conf)
