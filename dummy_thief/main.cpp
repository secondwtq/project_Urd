#include <string>
#include <iostream>
using namespace std;

const char *SERVER_IP = "172.27.35.1";
const unsigned int SERVER_PORT = 31000;

const char *SELF_IP = "172.27.35.3";
const unsigned int SELF_PORT = 31001;

extern "C" {
#include "LuaBridge/lua.h"
#include "LuaBridge/lualib.h"
#include "LuaBridge/lauxlib.h"
}
#include "LuaBridge/LuaBridge.h"

#include "SocketWrapper.h"

void inst_callback(const string& data, const string& attr);
void exit_app();
void lua_break_test();
void lua_restart();
void socket_send(const string& data);

SocketWrapper *sock = nullptr;
lua_State *luaG = nullptr;

void RegisterInterface(lua_State *L) {
	luabridge::getGlobalNamespace(L).
		beginNamespace("Utility").
			beginNamespace("Network").
				beginNamespace("Urd").
					addFunction("lua_break_test", &lua_break_test).
					addFunction("socket_send", &socket_send).
					addFunction("lua_restart", &lua_restart).
				endNamespace().
			endNamespace().
		endNamespace();
}

void inst_callback(const string& data, const string& attr) {
	auto parse_foo = luabridge::getGlobal(luaG, "inst_parser");
	parse_foo(data);
}

void socket_send(const string& data) {
	sock->send(data);
}

void lua_break_test() {
	printf("BAPol: lua_break_test called, pausing session...\n");
	sock->pause();
}

void lua_restart() {
	printf("BAPol: lua_restart called, entering prompt...\n");
}

void init() {
	luaG = luaL_newstate();
	luaL_openlibs(luaG);

	lua_pushstring(luaG, "LUABRIDG");
	lua_setglobal(luaG, "_URD_ENVTYPE_");

	RegisterInterface(luaG);

	sock = new SocketWrapper(SERVER_IP, SELF_IP, SERVER_PORT, SELF_PORT, inst_callback);
}

void dispose() {
	lua_close(luaG);
	delete sock;
}

void start() {
	if (luaL_dofile(luaG, "test.lua"))
		cout << "BAPol: luaL_dofile: Error in script!\n";
	auto init_foo = luabridge::getGlobal(luaG, "init");
	init_foo(SELF_PORT);
	sock->run();
}

int main(int argc, char const *argv[]) {
	init();
	start();
	// SocketWrapper t("172.27.35.3", SELF_IP, SERVER_PORT, SELF_PORT, [] (const string&, const string&) { });
	// t.set_recv_callback([&t] (const string& x, const string& y) { cout << x << endl; t.send("xxxxx"); });
	// printf("start running...\n");
	// t.run();
	// printf("running...\n");
	dispose();
	return 0;
}