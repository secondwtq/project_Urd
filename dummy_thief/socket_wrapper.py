# python
# coding: UTF-8

import socket
import time

class SocketWrapper(object):

	_BUFSIZE = 4096

	def __init__(self, server_ip, port_send, rec_ip, port_rec, rec_callback):
		self.server_ip, self.server_port = server_ip, port_send
		self.self_ip, self.self_port = rec_ip, port_rec
		self._server_loc = (self.server_ip, self.server_port)
		self._rec_callback = rec_callback
		self._isrunning = False

		self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
		self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
		self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
		self._sock.bind((self.self_ip, self.self_port))

	def run(self):
		self._isrunning = True
		while self._isrunning:
			data, addr = self._sock.recvfrom(self._BUFSIZE)
			print("PyPol (%d): data received from %s : %s" % (time.time() * 1000, addr, data))
			self._rec_callback(data, addr)

	def send(self, content):
		self.sendto(content, self.server_ip, self.server_port)
		# print("PyPol (%d): data sended to %s : %s" % (time.time() * 1000, self._server_loc, content))
		# self._sock.sendto(content, self._server_loc)

	def sendto(self, content, addr, port):
		print("PyPol (%d): data sended to %s:%d : %s" % (time.time() * 1000, addr, port, content))
		self._sock.sendto(content, (addr, port))

	def pause(self):
		# self._sock.close()
		self._isrunning = False

	def close(self):
		self.pause()
		print("PyPol: closing socket...")
		self._sock.close()
