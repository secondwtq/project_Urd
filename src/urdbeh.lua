dofile('lunalogger.lua')

function we_are_police()
	return Env.INST_INIT == 'POL' end

dofile('lunabehavior.lua')

function thief_found()
	print ("checking theif_found .. ", session_current.thives[1].found)
	return session_current.thives[1].found end

function get_theif_pos(id)
	if id == nil then id = 0 end
	return session_current.thives[id+1].pos
end

function find_search_pos(obj)
	local search_target_org = { session_current.map_obj.width-obj.pos[1]-1, session_current.map_obj.height-obj.pos[2]-1 }

	local xmin = session_current.sight_pol
	local ymin = session_current.sight_pol
	local xmax = session_current.map_obj.width - session_current.sight_pol
	local ymax = session_current.map_obj.height - session_current.sight_pol

	if search_target_org[1] < xmin then search_target_org[1] = xmin end
	if search_target_org[1] > xmax then search_target_org[1] = xmax end
	if search_target_org[2] < ymin then search_target_org[2] = ymin end
	if search_target_org[2] > ymax then search_target_org[2] = ymax end

	local _u = 1
	local _v = 1

	print("entering loop")
	for _ox = 0, session_current.map_obj.width/2 do
		for _oy = 0, session_current.map_obj.height/2 do
			local ox = _ox * _u
			local oy = _oy * _v

			local search_target = { search_target_org[1]+ox, search_target_org[2]+oy }

			if search_target[1] < 0 or search_target[1] > session_current.map_obj.width	or 
				search_target[2] < 0 or search_target[2] > session_current.map_obj.width then break end

			local cell = session_current.map_obj:getcell(table.unpack(search_target))
			local passable = cell:ispassable()

			if passable then return search_target end

			_v = _v * -1
		end
		_u = _u * -1
	end

end

function urdpol_init()
if we_are_police() then
	for i, char in ipairs(session_current.polices) do

		local node_search = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("Searching for target...")

			local search_target = find_search_pos(obj)

			print("Search dest set: ", search_target[1], search_target[2])

			while true do
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(search_target)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			return bt.state.SUCCESS
		end)

		local node_catch = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch mode...")

			while true do
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(target)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			return bt.state.SUCCESS
		end)

		print("initing brain...")

	char.brain =
		btnode_create_sequential()
			:add_child(
				btnode_createdec_cond(node_search, btnode_create_condition(thief_found, false)))
			:add_child(
				node_catch)

		logger = lloger:new()
		logger:init()
		logger.name_logger = 'BEH_LOGGER'

		char.brain:init({logger = logger})
		char.brain_activated = true
	end
end
end

function urdpol_tick()
if we_are_police() then
	for i,char in ipairs(session_current.polices) do

		if char.brain_activated then
			print("exectuing brain...")
			local status = char.brain:execute({obj = char})
			if status ~= bt.state.RUNNING then
				char.brain_activated = false
			end
		end

	end
end
end
