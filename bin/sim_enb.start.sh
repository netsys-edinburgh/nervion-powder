#!/bin/bash
CMAKE="/opt/oai/openairinterface5g/cmake_targets"
ENBCONFPATH="/usr/local/etc/oai/enb.conf"
ENBEXE="run_enb_ue_virt_s1"

# Kill off running function.
sudo killall -q $ENBEXE
sleep 1

# Do some cleanup.
screen -wipe >/dev/null 2>&1

cd $CMAKE
sudo -E screen -S sim_enb -d -m -h 10000 /bin/bash -c "tools/run_enb_ue_virt_s1 -c $ENBCONFPATH"


sudo screen -ls

exit 0
