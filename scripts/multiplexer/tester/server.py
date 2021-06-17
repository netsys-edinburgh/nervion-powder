import socket

core_address = ('192.168.56.102', 2152)
multi_address = ('192.168.56.1', 2152)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(core_address)

def getTEID(payload):
	teid = (payload[4] << 24) | (payload[5] << 16) | (payload[6] << 8) | payload[7]
	return teid

while(True):
	buf, address = sock.recvfrom(1024)
	print(address, '-> Received TEID:', getTEID(buf))
	sock.sendto(buf, address)