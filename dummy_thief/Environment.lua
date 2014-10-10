_ret = { }

print(_URD_HOSTTYPE_)

pkgutil = require 'ubtpkgutil'

if _URD_HOSTTYPE_ == 'LUATICPY' then

py = pkgutil.Require 'python'

_pg = py.globals()
_ret.Exit = _pg.lua_break_test
_ret.Send = _pg.sock.send
_ret.Restart = _pg.lua_restart
_ret.SendTo = _pg.sock.sendto

elseif _URD_HOSTTYPE_ == 'LUABRIDG' then

_ret.Exit = Utility.Network.Urd.lua_break_test
_ret.Send = Utility.Network.Urd.socket_send
_ret.Restart = Utility.Network.Urd.lua_restart

else

print('Unknown host type!')

end

_ret.INST_INIT = "THI"
_ret.SELF_PORT = 31002	-- will be inited by host with main.init()
_ret.TEAMNAME = "FLYIT_THIDUMMY"

return _ret