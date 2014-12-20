Environment = { }

print("_URD_HOSTTYPE_: " .. tostring(_URD_HOSTTYPE_))
print("_URD_HOSTPLATFORM_: " .. tostring(_URD_HOSTPLATFORM_))
print("_URD_HOSTPLATFORM_ISPOSIX_: " .. tostring(_URD_HOSTPLATFORM_ISPOSIX_))

if _URD_HOSTTYPE_ == 'LUATICPY' then

py = require ('python' .. '')

_pg = py.globals()
Environment.Exit = _pg.lua_break_test
Environment.Send = _pg.sock.send
Environment.Restart = _pg.lua_restart
Environment.SendTo = _pg.sock.sendto

elseif _URD_HOSTTYPE_ == 'LUABRIDG' then

Environment.Exit = Utility.Network.Urd.lua_break_test
Environment.Send = Utility.Network.Urd.socket_send
Environment.Restart = Utility.Network.Urd.lua_restart
Environment.SendTo = Utility.Network.Urd.socket_sendto

else

print('Unknown host type!')

end

Environment.INST_INIT = "THI"
Environment.SELF_PORT = 31001	-- will be inited by host with main.init()
Environment.TEAMNAME = "FLYIT"

return Environment
