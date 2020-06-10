#!/bin/bash
#set -u
#set -x

sudo /usr/local/src/srsLTE/srsepc/if_masq.sh eno1
sudo /usr/local/src/srsLTE/build/srsepc/src/srsepc /local/repository/config/srsepc/epc.config