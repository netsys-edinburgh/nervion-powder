#!/bin/bash
echo "Saving to file /local/repository/config/test/tshark-log.txt"
sudo tshark -o nas-5gs.null_decipher:true -i any -Y 'ngap && ip.addr == 192.168.4.80' -T fields -e frame.time_relative -e ngap.RAN_UE_NGAP_ID -e ngap.AMF_UE_NGAP_ID -e nas_5gs.sm.message_type -e nas_5gs.mm.message_type -e ngap.procedureCode -e ip.dst > /local/repository/config/test/tshark-log.txt
