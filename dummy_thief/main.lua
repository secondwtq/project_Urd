pkgutil = require 'ubtpkgutil'
Env = pkgutil.Require 'Environment'
Map = pkgutil.Require 'map'
Session = pkgutil.Require 'session'
Util = pkgutil.Require 'ubtutil'
Pathfinding = pkgutil.Require 'pathfinding'

pkgutil.Import('Defs.lua')

session_current = nil

-- interface, called to connect to server
function init(port)
	print("UltraBt: Initing...")
	Env.SELF_PORT = port and port or Env.SELF_PORT
	Env.Send(string.format("%s(%s, %d)", Env.INST_INIT, Env.TEAMNAME, Env.SELF_PORT))
end

-- interface, react to instructions
function inst_parser(inst)
	local _inst = inst
	local _inst_type = string.sub(_inst, 1, 3)
	local _inst_parse_switch = {
		END = inst_parser_end,
		INF = inst_parser_inf,
		INI = inst_parser_ini,

		-- changed in Urd: thief_dummy
		URD = function () init(Env.SELF_PORT) end,
	}
	_inst_parse_switch[_inst_type](_inst)
end

-- parse instruction 'INI': set basic attributes of entities, init map
function inst_parser_ini(inst)
	session_current = Session.SessionObject:new({ })
	print(session_current:debug_data())

	-- pattern matching to extract information
	local w, h = string.gmatch(inst, '%[(%d+),(%d+)%]')()
	local sp, st = string.gmatch(inst, '%<(%d+),(%d+)%>')()
	local np, nt = string.gmatch(inst, '%((%d+),(%d+)%)')()

	w, h, sp, st, np, nt = math.floor(tonumber(w)), math.floor(tonumber(h)), math.floor(tonumber(sp)), math.floor(tonumber(st)), math.floor(tonumber(np)), math.floor(tonumber(nt))

	-- set sights
	session_current.sight_pol, session_current.sight_thi = sp, st

	-- init entities
	session_current:init_entities(np, nt, Env.INST_INIT)
	local t = nil
	if Env.INST_INIT == 'POL' then t = session_current.polices else t = session_current.thives end
	local i = 1
	for id, x, y in string.gmatch(inst, '(%d+),(%d+),(%d+);') do
		id, x, y = math.floor(tonumber(id)), math.floor(tonumber(x)), math.floor(tonumber(y))
		t[i].id = id
		t[i]:setpos(x, y)
		i = i + 1
	end

	-- init map
	session_current.map_obj = Map.MapClass:new()
	session_current.map_obj:initmap(w, h)
	Pathfinding.pf_init(session_current.map_obj)

	-- print debug data
	print(session_current:debug_data())
	print(session_current.map_obj:debug_data())
end

-- parse instruction 'INF'
function inst_parser_inf(inst)
	local _clock, _time = os.clock(), os.time()

	-- pattern matching to extract information
	local _f_blocks = string.gmatch(inst, '%([%d,;]*%)')
	local pos_pols = _f_blocks()
	local blocks = _f_blocks()

	-- update police location
	for id, x, y in string.gmatch(pos_pols, '(%d+),(%d+),(%d+);') do
		id, x, y = math.floor(tonumber(id)), math.floor(tonumber(x)), math.floor(tonumber(y))
		local police = Util.findin(session_current.polices, function (o) return o.id == id end)
		police:setpos(x, y)
	end
	-- update terrain status
	for x, y in string.gmatch(blocks, '(%d+),(%d+);') do
		x, y = math.floor(tonumber(x)), math.floor(tonumber(y))
		session_current.map_obj:setcellexplored(x, y)
		session_current.map_obj:setcellunpassable(x, y)
	end

	-- get number of ticks
	local ntick = string.gmatch(inst, '%[(%d+)%]')()

	session_current:before_update()

	entities = {  }
	if Env.INST_INIT == 'POL' then
		entities.set = session_current.polices
		entities.sight = session_current.sight_pol
	elseif Env.INST_INIT == 'THI' then
		entities.set = session_current.thives
		entities.sight = session_current.sight_thi
	end
	Util.findin(entities.set, function (o)
			session_current.map_obj:update_explored(o, entities.sight)
			session_current.map_obj:update_onsight(o, entities.sight)
		end)

	-- changed in Urd: thief_dummy

	print(session_current.map_obj:debug_data())

	-- send move instruction
	Env.Send(session_current:pass_mov(ntick, Env.INST_INIT))
end

-- parse instruction 'END': close session, back to terminal
function inst_parser_end(inst)
	-- print debug data
	print(session_current:debug_data())
	print(session_current.map_obj:debug_data())

	-- reset session
	session_current = nil

	-- changed in Urd: thief_dummy

	-- restart
	-- Env.Exit()
	-- Env.Restart()
end