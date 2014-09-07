# python
# coding: UTF-8

import sys
from socket_wrapper import SocketWrapper

import lua

luaenv = lua.globals()

SERVER_IP = '172.27.35.1'
SERVER_PORT = 31000

SELF_IP = '172.27.35.3'
SELF_PORT = 31002

sock = None

# def start():
# 	global sock
# 	print "PyPol: initing game..."
# 	sock = SocketWrapper(SERVER_IP, SERVER_PORT, SELF_IP, SELF_PORT, inst_callback)
# 	lua.globals().dofile('test.lua')
# 	lua.globals().init(SELF_PORT)
# 	sock.run()

def main():
	sock = SocketWrapper('127.0.0.1', SELF_PORT, SELF_IP, SERVER_PORT, lambda x, y: 0)
	sock.send('xxx')
	sock.run()

if __name__ == '__main__':
	status = main()
	sys.exit(status)