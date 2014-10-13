dofile('lunalogger.lua')

Util = require 'ubtutil'

function we_are_police()
	return Env.INST_INIT == 'POL' end

dofile('lunabehavior.lua')

function thief_found()
	print ("checking theif_found .. ", session_current.thives[1].found)
	return session_current.thives[1].found end

function thief_onsight(id)
	print("checking thief_onsight .. ", session_current.thives[id].onsight)
	return session_current.thives[id].onsight
end

function get_theif_pos(id)
	if id == nil then id = 0 end
	return session_current.thives[id+1].pos
end

function count_of_state_pol(state)
	io.write("counting state in polices\t", state)
	local ret = 0;
	for i, v in ipairs(session_current.polices) do
		if v._catch_state == state then
			ret = ret + 1
		end
	end
	print('\t', ret)
	return ret
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

function get_furthest_cell(current, direction, max_step, enable_bound)
	if max_step == nil then max_step = 1024 end
	if enable_bound == nil then enable_bound = true end

	if direction[1] == 0 and direction[2] == 0 then return current end

	local cur = current
	local prev_cur = nil

	local i = 0
	while true do
		if i >= max_step then return cur end
		i = i+1

		prev_cur = cur
		cur = Util.add_2dpos(cur, direction)

		local cell = session_current.map_obj:getcell(unpack(cur))
		if (not cell) or (not cell:ispassable()) then
			print ("\t\tget_furthest_cell returning normal")
			return prev_cur
		end

		if enable_bound and ((Util.equ_2dpos(direction, {1, 0}) and cur[1] >= current[1]) or 
					(Util.equ_2dpos(direction, {-1, 0}) and cur[1] <= current[1]) or
					(Util.equ_2dpos(direction, {0, 1}) and cur[2] >= current[2]) or
					(Util.equ_2dpos(direction, {0, -1}) and cur[2] <= current[2])) then
			print ("\t\tget_furthest_cell returning self boundary")
			return cur
		end

	end

end

function get_lead_cell(current_pos, target_pos, target_direction)
	local lookAheadTime = Util.distance_manhattan(current_pos, target_pos) / 2
	return get_furthest_cell(target_pos, target_direction, math.ceil(lookAheadTime), false)
end

function is_actually_front(pos0, pos1, direction)
	local vec_dis = Util.add_2dpos(pos1, Util.mul_2dpos(pos0, -1))
	local relative = Util.dot_2dpos(Util.nom_2dpos(vec_dis), Util.nom_2dpos(direction))
	return relative < -0.86
end

function is_actually_behind(pos0, pos1, direction)
	return is_actually_front(pos0, pos1, Util.mul_2dpos(direction, -1))
end

function is_actually_side(pos0, pos1, direction)
	if is_actually_front(pos0, pos1, direction) == false and is_actually_behind(pos0, pos1, direction) == false then return true
	else return false end
end

function set_all_unpassable(set, except)
	for i, v in ipairs(set) do
		if v ~= except then
			session_current.map_obj:getcell(table.unpack(v.pos)):setunpassable(true)
		end
	end
end

function reset_unpassable(set)
	for i, v in ipairs(set) do
		if v ~= except then
			session_current.map_obj:getcell(table.unpack(v.pos)):setunpassable(false)
		end
	end
end

function urdpol_init()
if we_are_police() then
	for i, char in ipairs(session_current.polices) do

		char._catch_state = 'NONE'

		local node_search = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("Searching for target...")

			local search_target = find_search_pos(obj)

			print("Search dest set: ", search_target[1], search_target[2])

			while true do
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				set_all_unpassable(session_current.polices, obj)
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(search_target)), cache)
				reset_unpassable(session_current.polices)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			return bt.state.SUCCESS
		end)

		local node_catch = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch mode...")

			while true do
				print("\tnode_catch catching...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				-- set_all_unpassable(session_current.polices, obj)
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(target)), cache)
				-- reset_unpassable(session_current.polices)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			print("catch success")
			return bt.state.SUCCESS
		end)

		local node_catch_further = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch further mode...")

			while true do
				print("\tnode_catch_further catching further...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				local furthest = get_furthest_cell(target, session_current.thives[1]:get_move_direction_vector_single())
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(furthest)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			print ("catch further success")
			return bt.state.SUCCESS
		end)

		local node_catch_lead = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch lead mode...")

			while true do
				print("\tnode_catch_lead catching lead...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				local lead_cell = get_lead_cell(char.pos, target, session_current.thives[1]:get_move_direction_vector_single())
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(lead_cell)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			print ("catch lead success")
			return bt.state.SUCCESS
		end)

		local node_cache_behind = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch behind mode...")

			while true do
				print("\tnode_cache_behind catching behind...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				local behind = get_furthest_cell(target, Util.mul_2dpos(session_current.thives[1]:get_move_direction_vector_single(), -1), 4)
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(behind)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			print ("catch behind success")
		end)


		print("initing brain...")

	char.brain = btnode_create_repeat(1024,
		btnode_create_sequential()
			:add_child(
				btnode_createdec_cond(
					btnode_create_sequential()
						:add_child(btnode_create_coroutine(function () char._catch_state = 'INITIAL' return bt.state.SUCCESS end))
						:add_child(node_search),
					btnode_create_condition(thief_found, false)))
			:add_child(
				btnode_createdec_cond(
					btnode_create_sequential()
						:add_child(btnode_create_coroutine(function () char._catch_state = 'SEARCH' return bt.state.SUCCESS end))
						:add_child(node_search),
					btnode_create_condition(function ()
						return thief_onsight(1) end, false)))
			:add_child(
				btnode_create_priority_cond()
					:add_child(
						btnode_createdec_cond(node_catch, 
							btnode_create_condition(function ()
								return is_actually_front(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()) end),
							bt.state.FAILURE, "CATCH_ACTUALLY_FRONT"))
					:add_child(
						btnode_createdec_cond(
							btnode_create_sequential()
								:add_child(btnode_create_coroutine(function () char._catch_state = 'NEAR' return bt.state.SUCCESS end))
								:add_child(node_catch_lead),
							btnode_create_condition(function ()
								return Util.distance(char.pos, session_current.thives[1].pos) <= 2 and count_of_state_pol('NEAR') < 1 end),
						bt.state.FAILURE, "CATCH_NEAR"))
					:add_child(
						btnode_createdec_cond(
							btnode_create_sequential()
								:add_child(btnode_create_coroutine(function () char._catch_state = 'BEHIND' return bt.state.SUCCESS end))
								:add_child(node_cache_behind),
							btnode_create_condition(function ()
								return char:is_behind(session_current.thives[1]) and is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()) and count_of_state_pol('BEHIND') < 2 end),
							bt.state.FAILURE, "CATCH_BEHIND"))
					:add_child(
						btnode_createdec_cond(
							btnode_create_sequential()
								:add_child(btnode_create_coroutine(function () char._catch_state = 'FUR' return bt.state.SUCCESS end))
								:add_child(node_catch_further),
							btnode_create_condition(function ()
								return (is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()) and count_of_state_pol('FUR') < 2) end),
						bt.state.FAILURE, "CATCHFUR"))
					:add_child(
						btnode_createdec_cond(
							btnode_create_sequential()
								:add_child(btnode_create_coroutine(function () char._catch_state = 'SIDE' return bt.state.SUCCESS end))
								:add_child(node_catch_lead),
							btnode_create_condition(function ()
								return char:is_on_side_of(session_current.thives[1]) and count_of_state_pol('SIDE') < 1 end, true),
						bt.state.FAILURE, "CATCHSIDE"))
					:add_child(
						btnode_createdec_cond(node_catch,
							btnode_create_condition(function ()
								return char:is_in_front_of(session_current.thives[1]) end),
						bt.state.FAILURE, "CATCHFRONT"))
					:add_child(
						btnode_create_sequential()
							:add_child(btnode_create_coroutine(function () char._catch_state = 'LAST' return bt.state.SUCCESS end))
							:add_child(node_catch_further)
					)
			)
		)

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
	for i, char in ipairs(session_current.polices) do

		if char.brain_activated then
			print("exectuing brain...")
			local status = char.brain:execute({obj = char})
			if status ~= bt.state.RUNNING then
				char.brain_activated = false
			end
		end

		print('')
		print("Catch mode: ", char._catch_state)
		print("Is behind of thief: ", char:is_behind(session_current.thives[1]))
		print("Is on side of thief: ", char:is_on_side_of(session_current.thives[1]))
		print("Is on the exact side of thief: ", is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()))
		print("Is in front of thief: ", char:is_in_front_of(session_current.thives[1]))
		print("Is on the exact front of thief: ", is_actually_front(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()))
		print('')

	end

	local t = session_current.thives[1]:get_move_direction_vector_single()
	print("Thief 0 move vector: ", t[1], t[2])
end
end
