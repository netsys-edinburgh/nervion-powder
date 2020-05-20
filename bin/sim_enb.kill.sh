#!/bin/bash

ENBEXE="run_enb_ue_virt_s1"

# Kill off running function.
killall -q $ENBEXE
sleep 1

# Do some cleanup.
screen -wipe >/dev/null 2>&1

exit 0
