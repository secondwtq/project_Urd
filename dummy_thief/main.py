# python
# coding: UTF-8

import sys
from socket_wrapper import SocketWrapper

import lua

luaenv = lua.globals()

SERVER_IP = '172.27.35.1'
SERVER_PORT = 31000

SELF_IP = '172.27.35.3'
SELF_PORT = 31001

sock = None

def inst_callback(data, attr):
	lua.execute("inst_parser('%s')" % data)

def exit_app():
	print "PyPol: exiting..."
	if sock: sock.close()
	sys.exit(0)

def lua_break_test():
	print "PyPol: lua_break_test called, pausing session..."
	sock.pause()

def lua_restart():
	print "PyPol: lua_restart called, entering prompt..."
	prompt()

def prompt():
	_dswitch = {
		'start' : start,
		's' : start,
		'exit' : exit_app,
		'e' : exit_app,
		'r' : start,
		'restart' : start
	}
	print "PyPol: waiting for command..."
	_x = raw_input('→_→ ').lower()
	_dswitch.get(_x, lambda : 0)()

def start():
	global sock
	print "PyPol: initing game..."
	sock = SocketWrapper(SERVER_IP, SERVER_PORT, SELF_IP, SELF_PORT, inst_callback)
	lua.globals()['_URD_ENVTYPE_'] = 'LUATICPY'
	lua.globals().dofile('test.lua')
	lua.globals().init(SELF_PORT)
	sock.run()

def main():
	print '第五次最终究极嘎七姆七圣杯妮可妮可妮超红莲圣天八极式机巧尼姆合金雌鲍兄贵扎夫特原型机魔改试做量产红色扎古型黑炎龙新日暮里更衣室胖次无限鬼畜Deep♂Dark♂Fantasy摔跤大战·改·完结篇完美睾清第二次重制初回现场限定特典十二周年纪念精制经典浪漫怀旧18X特别友情免费放送豪华精装定制无码VIP限定网络下载畅玩不删档中国区威力增强完善平衡公测OMEGA版pc小霸王mac任天堂ps3安卓xbox黑莓wp塞班ios多平台共存体感操控通用整合包逗遥特别专用版警察抓小偷游戏警察 AI 服务器 控制终端 by secondwtq'
	print('')
	prompt()

if __name__ == '__main__':
	status = main()
	sys.exit(status)