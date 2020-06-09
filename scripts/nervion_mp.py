import threading
import socket
import sys
import signal

class NervionMultiplexer:
		
	def __init__(self, multi, ip):
		self.routes = {}
		self.spgw_ip = ip
		self.multi = multi

	def processMessage(self, payload, address):
		teid = (ord(payload[4]) << 24) | (ord(payload[5]) << 16) | (ord(payload[6]) << 8) | ord(payload[7])
		self.routes[teid] = address

	def getAddress(self, payload):
		teid = (ord(payload[4]) << 24) | (ord(payload[5]) << 16) | (ord(payload[6]) << 8) | ord(payload[7])
		return self.routes.get(teid)

	def downlink(self):
		print('Initiating Downlink thread...')
		internal_address = self.multi
		internal_port = 2152
		internal = (internal_address, internal_port)
		self.internal_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		self.internal_sock.bind(internal)

		while True:
			payload, epc_address = self.internal_sock.recvfrom(65536)
			ue_address = self.getAddress(payload)
			if ue_address != None:
				self.public_sock.sendto(payload, ue_address)

	def uplink(self):
		print('Initiating Uplink thread...')
		server_address = self.multi
		server_port = 2154
		server = (server_address, server_port)
		self.public_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		self.public_sock.bind(server)

		while True:
			payload, ue_address = self.public_sock.recvfrom(65536)
			self.processMessage(payload, ue_address)
			self.internal_sock.sendto(payload, (self.spgw_ip, 2152))


	def start(self):
		downlink_t = threading.Thread(target=self.downlink)
		uplink_t = threading.Thread(target=self.uplink)

		downlink_t.start()
		uplink_t.start()

if __name__ == '__main__':
	if len(sys.argv) != 3:
		print('USAGE: python3 nervion_mp.py <MULTIPLEXER_IP> <SPGW_IP>')
		exit(1)
	nm = NervionMultiplexer(sys.argv[1], sys.argv[2])
	nm.start()
