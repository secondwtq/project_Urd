#include <cstdlib>

#include <iostream>
#include <string>
using namespace std;

#include <boost/predef.h>
#include <boost/program_options.hpp>

extern "C" {
#include "LuaBridge/lua.h"
#include "LuaBridge/lualib.h"
#include "LuaBridge/lauxlib.h"
}
#include "LuaBridge/LuaBridge.h"

#include "SocketWrapper.h"
#include "Map.h"
#include "Utils.h"
#include "Pathfinding.h"

string TEAM_NAME = "FLYIT";

string SERVER_IP = "127.0.0.1";
unsigned int SERVER_PORT = 31000;

string SELF_ROLE = "POL";

const char *SELF_IP = "172.27.35.3";
unsigned int SELF_PORT = 31002;

string LUA_MAINSCRIPT = "";

void inst_callback(const string& data, const string& attr);
void exit_app();
void lua_break_test();
void lua_restart();
void socket_sendto(const string& data, const string& address, unsigned int port);
void socket_send(const string& data);

SocketWrapper *sock = nullptr;
lua_State *L = nullptr;

void RegisterInterface(lua_State *L) {
	luabridge::getGlobalNamespace(L).
		beginNamespace("Utility").
			addFunction("GetTime", &LuaUtils::GetTime).
			beginClass<CellStruct>("CellStruct").
				addData("x", &CellStruct::x).
				addData("y", &CellStruct::y).
				addConstructor<void (*)(int, int)>().
			endClass().
			beginNamespace("Urd").
				beginNamespace("Pathfinding").
					addFunction("pf_init", &Pathfinding::pf_init).
					addFunction("pf_dispose", &Pathfinding::pf_dispose).
					addFunction("find", &Pathfinding::find).
					addFunction("find_8", &Pathfinding::find_8).
					beginClass<Pathfinding::Pathfindingcache>("Pathfindingcache").
						addConstructor<void (*)()>().
						addFunction("next", &Pathfinding::Pathfindingcache::next).
						addFunction("getCur", &Pathfinding::Pathfindingcache::getCur).
						addFunction("ended", &Pathfinding::Pathfindingcache::ended).
						addFunction("setobegin", &Pathfinding::Pathfindingcache::setobegin).
					endClass().
				endNamespace().
				beginClass<CellClass>("CellClass").
					addFunction("ispassable", &CellClass::ispassable).
					addFunction("setunpassable", &CellClass::setunpassable).
					addFunction("isexplored", &CellClass::isexplored).
					addFunction("setexplored", &CellClass::setexplored).
					addFunction("isonsight", &CellClass::isonsight).
					addFunction("setonsight", &CellClass::setonsight).
					addFunction("isonpath", &CellClass::isonpath).
					addFunction("setonpath", &CellClass::setonpath).
					addFunction("getpos", &CellClass::getpos).
					addFunction("setinflfac", &CellClass::setinflfac).
					addFunction("getinflfac", &CellClass::getinflfac).
				endClass().
				beginClass<MapClass>("MapClass").
					addConstructor<void (*)()>().
					addData("width", &MapClass::width).
					addData("height", &MapClass::height).
					addFunction("initmap", &MapClass::initmap).
					addFunction("getcell", &MapClass::getcell).
					addFunction("update_explored", &MapClass::update_explored).
					addFunction("update_onsight", &MapClass::update_onsight).
					addFunction("clear_on_sight", &MapClass::clear_on_sight).
					addFunction("clear_on_path", &MapClass::clear_on_path).
					addFunction("clear_influence", &MapClass::clear_influence).
				endClass().
			endNamespace().
			beginNamespace("Network").
				beginNamespace("Urd").
					addFunction("lua_break_test", &lua_break_test).
					addFunction("socket_sendto", &socket_sendto).
					addFunction("socket_send", &socket_send).
					addFunction("lua_restart", &lua_restart).
				endNamespace().
			endNamespace().
		endNamespace();
}

void socket_sendto(const string& data, const string& address, unsigned int port) {
	sock->send_to(data, address, port);
}

void socket_send(const string& data) { sock->send(data); }

void lua_break_test() {
	printf("BAPol: lua_break_test called, pausing session...\n");
	sock->pause();
}

void lua_restart() { printf("BAPol: lua_restart called, entering prompt...\n"); }

void init() {
	cout << "BAPol: init: program start ...\n";
	L = luaL_newstate();
	luaL_openlibs(L);
	cout << "BAPol: init: lua_state created.\n";

	cout << "BAPol: init: setting environment ...\n";
	lua_pushstring(L, "LUABRIDG");
	lua_setglobal(L, "_URD_HOSTTYPE_");

	#if BOOST_OS_MACOS
		lua_pushboolean(L, true);
		lua_setglobal(L, "_URD_HOSTPLATFORM_ISPOSIX_");

		lua_pushstring(L, "DARWIN");
	#elif BOOST_OS_UNIX
		lua_pushboolean(L, true);
		lua_setglobal(L, "_URD_HOSTPLATFORM_ISPOSIX_");

		lua_pushstring(L, "POSIX");
	#elif BOOST_OS_WINDOWS
		lua_pushboolean(L, false);
		lua_setglobal(L, "_URD_HOSTPLATFORM_ISPOSIX_");

		lua_pushstring(L, "WINDOWS");
	#else
		lua_pushboolean(L, false);
		lua_setglobal(L, "_URD_HOSTPLATFORM_ISPOSIX_");

		lua_pushstring(L, "UNKNOWN");
	#endif
	lua_setglobal(L, "_URD_HOSTPLATFORM_");

	cout << "BAPol: init: initing interface ...\n";
	RegisterInterface(L);
	LuaUtils::init();

	sock = new SocketWrapper(SERVER_IP, SELF_IP, SERVER_PORT, SELF_PORT, [] (const string& data, const string& attr) {
		auto parse_foo = luabridge::getGlobal(L, "inst_parser");
		parse_foo(data);
	});
}

void dispose() {
	lua_close(L);
	L = nullptr;

	delete sock;
	sock = nullptr;
}

void start() {
	cout << "BAPol: start: loading script ...";
	if (LUA_MAINSCRIPT == "") {
		#include "main.luacb"
		cout << " internal \n";
		if (luaL_loadbuffer(L,(const char*)_URD_LUACB_DATA_,sizeof(_URD_LUACB_DATA_),"urdmain.luap")==0) lua_pcall(L, 0, 0, 0);
	} else {
		cout << " external " << LUA_MAINSCRIPT << " " << endl;
		if (luaL_dofile(L, LUA_MAINSCRIPT.c_str()))
			cout << "BAPol: luaL_dofile: Error in script!\n";
	}

	auto init_foo = luabridge::getGlobal(L, "init");

	cout << "BAPol: start: calling init function ...\n";
	//	`function init(port, init_inst, teamname)
	init_foo(SELF_PORT, SELF_ROLE, TEAM_NAME);

	cout << "BAPol: start: starting socket ...\n";
	sock->run();
}

namespace _argparser = boost::program_options;

void parse_cmd_args(int argc, const char *argv[]) {
	//	options description
	_argparser::options_description _argparser_desc("Allowed options");
	_argparser_desc.add_options()
		("help,h", "display help message.")
		("teamname,n", _argparser::value<string>(&TEAM_NAME)->default_value(TEAM_NAME), "set the teamname.")
		("serverip,t", _argparser::value<string>(&SERVER_IP)->default_value(SERVER_IP), "set the IP address of server.")
		("serverport,s", _argparser::value<unsigned int>(&SERVER_PORT)->default_value(SERVER_PORT), "set the receive port of server.")
		("instrole,i", _argparser::value<string>(&SELF_ROLE)->default_value(SELF_ROLE), "set the role of client.")
		("recport,r", _argparser::value<unsigned int>(&SELF_PORT)->default_value(SELF_PORT), "set the receive port of client.")
		("userscript,u", _argparser::value<string>(&LUA_MAINSCRIPT), "set the main script file, use the internal one if empty.");

	//	positional options
	_argparser::positional_options_description pos_desc;
	pos_desc.add("teamname", 1).add("serverip", 1).add("serverport", 1).add("instrole", 1).add("recport", 1);

	//	read and store options
	_argparser::variables_map _argparser_vm;
	_argparser::store(_argparser::command_line_parser(argc, argv).options(_argparser_desc).positional(pos_desc).run(),
						_argparser_vm);
	_argparser::notify(_argparser_vm);

	//	display help message and exit
	if (_argparser_vm.empty() || _argparser_vm.count("help")) {
		cout << _argparser_desc << endl;
		exit(0);
	}
}

int main(int argc, char const *argv[]) {
	parse_cmd_args(argc, argv);
	init();
	start();
	dispose();
	return 0;
}
