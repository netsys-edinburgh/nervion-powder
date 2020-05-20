#!/bin/bash

cd /opt/oai/openair-cn/scripts

# Kill off running function.
./run_spgw -k
sleep 1

# Do some cleanup.
screen -wipe >/dev/null 2>&1

exit 0
