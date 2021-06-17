#!/bin/bash

cd /local/repository/scripts/multiplexer/
make
./nervion_multiplexer 192.168.4.81 192.168.4.80 &