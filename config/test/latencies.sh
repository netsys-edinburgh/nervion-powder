#!/bin/bash

# Script to display the NGAP / NAS latencies

# Run tshark
# Decoding NAS 5G messages (since we use EE0 encryption)
# Capture on any interface
# Display time format as relative (easier for showing message latencies)
# Only display NGAP messages sent or received on 192.168.4.80

sudo tshark \
    -o nas-5gs.null_decipher:TRUE \
    -i any \
    -t dd \
    -Y 'ngap and (ip.src == 192.168.4.80 or ip.dst == 192.168.4.80)'
