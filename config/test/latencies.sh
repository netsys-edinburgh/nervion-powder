#!/bin/bash

# Script to display the NGAP / NAS latencies

# Run tshark
# Decoding NAS 5G messages (since we use EE0 encryption)
# Capture on any interface
# Display time format as relative (easier for showing message latencies)
# Only display NGAP messages sent or received on 192.168.4.80

# Explaining the sed lines (line by line):
# Replace the IP of the CoreKube node with the word "CoreKube"
# Replace the IP of the Nervion node with the word "Nervion"
# Remove the SACK part (not relevent)
# Remove trailing spaces before commas
# Remove the packet number at the start of the line
# Remove the NAS type information (not relevent)
# Add some newlines and "***" between attach-detach blocks
# Print Nervion -> CoreKube messages in red
# Print CoreKube -> Nervion messages in green

sudo tshark \
    -l \
    -o nas-5gs.null_decipher:TRUE \
    -i any \
    -t dd \
    -Y 'ngap and (ip.addr == 192.168.4.80)' 2> /dev/null \
| sed -u 's/192.168.4.80/CoreKube/' \
| sed -u 's/192.168.4.8[1-9]/Nervion/' \
| sed -u -E 's/SACK \(Ack=[0-9]+, Arwnd=[0-9]+\) //' \
| sed -u 's/ , /, /' \
| sed -u -E 's/^ *[0-9]+ //' \
| sed -u -E 's/\/NAS-5GS(\/NAS-5GS)?//' \
| sed -u -E 's/UEContextReleaseComplete/&\n\n\*\*\*\n/' \
| sed -u -E 's/Nervion → CoreKube/\x1B[31mNervion → CoreKube\x1B[0m/' \
| sed -u -E 's/CoreKube → Nervion/\x1B[32mCoreKube → Nervion\x1B[0m/'
