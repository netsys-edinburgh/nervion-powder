import socket
import time

def assembleMSG(teid):
	buf = bytearray()
	buf.append(0x00)
	buf.append(0x00)
	buf.append(0x00)
	buf.append(0x00)
	buf.append((teid >> 24) & 0xFF)
	buf.append((teid >> 16) & 0xFF)
	buf.append((teid >> 8) & 0xFF)
	buf.append(teid & 0xFF)
	buf.append(0xFF)
	return buf

def getTEID(payload):
	teid = (payload[4] << 24) | (payload[5] << 16) | (payload[6] << 8) | payload[7]
	return teid

multiplexer = ('192.168.56.1', 2154)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

for i in range(5):
	teid = 1
	buf = assembleMSG(teid)
	print('Sending TEID:', teid)
	sock.sendto(buf, multiplexer)
	buf, address = sock.recvfrom(1024)
	print('Received TEID:', getTEID(buf))
	time.sleep(2)
