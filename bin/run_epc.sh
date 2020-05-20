#!/bin/bash

./hss.kill.sh
./mme.kill.sh
./spgw.kill.sh

./hss.start.sh
./mme.start.sh
./spgw.start.sh

tail -f /var/log/oai/mme.log