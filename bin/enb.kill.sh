#!/bin/bash

ENBEXE="lte-softmodem.Rel14"

# Kill off running function.
killall -q $ENBEXE
sleep 1

# Do some cleanup.
screen -wipe >/dev/null 2>&1

exit 0
