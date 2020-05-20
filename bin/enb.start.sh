#!/bin/bash

OAIRANDIR="/opt/oai/openairinterface5g"
OAIETCDIR="/local/repository/etc"
ENBEXE="lte-softmodem.Rel14"
ENBEXEPATH="$OAIRANDIR/targets/bin/$ENBEXE"
ENBCONFPATH="/usr/local/etc/oai/enb.conf"

cd /var/tmp

# Kill off running function.
killall -q $ENBEXE
sleep 1

# Startup function.
screen -c $OAIETCDIR/enb.screenrc -L -S enb -d -m -h 10000 /bin/bash -c "$ENBEXEPATH -O $ENBCONFPATH"

# Do some cleanup.
screen -wipe >/dev/null 2>&1

exit 0
