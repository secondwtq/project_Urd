Env = require 'Environment'
Session = require 'session'
Util = require 'ubtutil'

directions = require 'directions'

session_current = nil

-- interface, called to connect to server
function init(port, init_inst, teamname)
	print("UltraBt: Initing...")

	Env.SELF_PORT = port and port or Env.SELF_PORT
	Env.INST_INIT = init_inst and init_inst or Env.INST_INIT
	Env.TEAMNAME = teamname and teamname or Env.TEAMNAME

	Env.Send(string.format("%s(%s, %d)", Env.INST_INIT, Env.TEAMNAME, Env.SELF_PORT))

	-- init dummy thief, for automatic testing
	if Env.INST_INIT == "POL" then Env.SendTo("URD", "localhost", 31001) end
end

-- interface, react to instructions
function inst_parser(inst)
	local _inst = inst
	local _inst_type = string.sub(_inst, 1, 3)
	local _inst_parse_switch = {
		END = inst_parser_end,
		INF = inst_parser_inf,
		INI = inst_parser_ini,
	}
	_inst_parse_switch[_inst_type](_inst)
end

-- parse instruction 'END': close session, back to terminal
function inst_parser_end(inst)
	-- print debug data
	print(session_current:debug_data())
	-- print(session_current.map_obj:debug_data())

	-- reset session
	session_current = nil
	Utility.Urd.Pathfinding.pf_dispose()

	-- restart
	Env.Exit()
	Env.Restart()
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
	session_current.map_obj = Utility.Urd.MapClass() -- Map.MapClass:new()
	session_current.map_obj:initmap(w, h)
		-- changed in CPath
	Utility.Urd.Pathfinding.pf_init(session_current.map_obj)

	-- print debug data
	print(session_current:debug_data())
		-- changed in CPath
	print(Util.map_debug_data(session_current.map_obj))
end

-- parse instruction 'INF'
function inst_parser_inf(inst)
	local _clock, _time = os.clock(), os.time()

	-- pattern matching to extract information
	local _f_blocks = string.gmatch(inst, '%([%d,;]*%)')
	local pos_pols = _f_blocks()
	local blocks = _f_blocks()
	local thi_blocks = string.gmatch(str_test, '%<[%d,;]*%>')()

	-- update police location
	for id, x, y in string.gmatch(pos_pols, '(%d+),(%d+),(%d+);') do
		id, x, y = math.floor(tonumber(id)), math.floor(tonumber(x)), math.floor(tonumber(y))
		local police = Util.findin(session_current.polices, function (o) return o.id == id end)
		police:setpos(x, y)
	end

	-- update thief location
	for id, x, y in string.gmatch(thi_blocks, '(%d+),(%d+),(%d+);') do
		id, x, y = math.floor(tonumber(id)), math.floor(tonumber(x)), math.floor(tonumber(y))
		local thief = Util.findin(session_current.thives, function (o) return o.id == id end)
		thief:setpos(x, y)
	end

	-- update terrain status
	for x, y in string.gmatch(blocks, '(%d+),(%d+);') do
		x, y = math.floor(tonumber(x)), math.floor(tonumber(y))
		-- changed in CPath
		local cell = session_current.map_obj:getcell(x, y)
		cell:setexplored(true)
		cell:setunpassable(true)
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
			-- changed in CPath
			session_current.map_obj:update_explored(Utility.CellStruct(o:getpos()[1], o:getpos()[2]), entities.sight)
			session_current.map_obj:update_onsight(Utility.CellStruct(o:getpos()[1], o:getpos()[2]), entities.sight)
		end)

	-- changed in CPath
	for k, v in ipairs(session_current.polices) do
		local cache = Utility.Urd.Pathfinding.Pathfindingcache()
		Utility.Urd.Pathfinding.find(v:getcell(session_current.map_obj), session_current.map_obj:getcell(21, 21), cache)
		if not cache:ended() then v:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
	end

	-- changed in CPath
	print(Util.map_debug_data(session_current.map_obj))

	-- for k, v in ipairs(session_current.polices) do
	-- 	if Map.iscellpassable(session_current.map_obj:getneighborcell(v:getcell(session_current.map_obj), Directions.Up)) then v:move(Directions.Up)
	-- 	elseif Map.iscellpassable(session_current.map_obj:getneighborcell(v:getcell(session_current.map_obj), Directions.Down)) then v:move(Directions.Down)
	-- 	elseif Map.iscellpassable(session_current.map_obj:getneighborcell(v:getcell(session_current.map_obj), Directions.Left)) then v:move(Directions.Left)
	-- 	elseif Map.iscellpassable(session_current.map_obj:getneighborcell(v:getcell(session_current.map_obj), Directions.Right)) then v:move(Directions.Right)
	-- 	end
	-- end

	local _clock_, _time_ = os.clock(), os.time()
	print(_clock, _clock_, _clock_-_clock)
	print(_time, _time_, _time_-_time)

	-- send move instruction
	Env.Send(session_current:pass_mov(ntick, Env.INST_INIT))
end