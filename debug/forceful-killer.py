import socket
import sys
import time

if len(sys.argv) == 2:
    ip = sys.argv[1]
    port = 5566
else:
    print("Run like : python3 client.py <arg1 server ip 192.168.1.102>")
    exit(1)

# Create socket for server
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)

# Let's send data through UDP protocol
while True:
    time.sleep(3)
    s.sendto("kil".encode('utf-8'), (ip, port))
# close the socket
s.close()
