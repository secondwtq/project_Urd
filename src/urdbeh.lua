dofile('lunalogger.lua')

dofile('lunabehavior.lua')

function we_are_police()
	return Env.INST_INIT == 'POL' end

function thief_found()
	do return false end
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

function count_of_state_pol_except(obj, state)
	io.write("counting state in polices\t", state)
	local ret = 0;
	for i, v in ipairs(session_current.polices) do
		if v._catch_state == state and v ~= obj then
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

	-- print("entering loop")
	-- while true do
	-- 	print("loop entered")
	-- 	local vec_random = vhere.vector2d(math.random(), math.random())
	-- 	print("vec random created")
	-- 	vec_random:nom()

	-- 	print("vec random got")
	-- 	local radius = math.min(session_current.map_obj.width, session_current.map_obj.height)/2
	-- 	vec_random = vec_random * radius
	-- 	print("vec world scaled")

	-- 	local vec_world = tyre.coord_return(vhere.vector2d(obj.pos[1], obj.pos[2]), vhere.vector2d(0, 1), vec_random)

	-- 	print("vec world got")
	-- 	vec_world.x = math.floor(vec_world.x)
	-- 	vec_world.y = math.floor(vec_world.y)

	-- 	local cell = session_current.map_obj:getcell(vec_world:unpack())

	-- 	print("cell found")
	-- 	if cell then

	-- 		local passable = cell:ispassable()

	-- 		if passable then
	-- 			print("returning ", vec_world:unpack())
	-- 			return { vec_world.x, vec_world.y }
	-- 		end

	-- 	end
	-- end

end

function get_random_cell(origin, radius)
	local rx = math.random(-radius, radius)
	local ry = math.random(-radius, radius)

	local pos = Util.add_2dpos(origin, {rx, ry})

	local cell = session_current.map_obj:getcell(table.unpack(pos))

	if cell and cell:ispassable() and (Util.distance_sqrt(pos, origin) <= radius)then return pos
	else return get_random_cell(origin, radius) end
end

function get_furthest_cell(current, direction, self_pos, max_step, enable_bound, allow_turn)
	print(self_pos[1], self_pos[2])

	if max_step == nil then max_step = 1024 end
	if enable_bound == nil then enable_bound = true end
	if allow_turn == nil then allow_turn = false end

	if direction[1] == 0 and direction[2] == 0 then return current end

	local cur = current
	local prev_cur = nil

	local i = 0
	while true do

		if i >= max_step then
			local cell = session_current.map_obj:getcell(unpack(cur))
			print ("\t\tget_furthest_cell returning max step")
			if (not cell) or (not cell:ispassable()) then return cur
			else return prev_cur end
		end
		i = i+1

		prev_cur = cur
		cur = Util.add_2dpos(cur, direction)

		local cell = session_current.map_obj:getcell(unpack(cur))
		if (not cell) or (not cell:ispassable()) then
			print ("\t\tget_furthest_cell returning normal")
			if allow_turn then
				return get_furthest_cell(cur, Util.right_angel_vec(direction), self_pos, max_step-i-1+1, enable_bound, false)
			else return prev_cur end
		end

		if enable_bound and ((Util.equ_2dpos(direction, {1, 0}) and cur[1] >= self_pos[1]) or
					(Util.equ_2dpos(direction, {-1, 0}) and cur[1] <= self_pos[1]) or
					(Util.equ_2dpos(direction, {0, 1}) and cur[2] >= self_pos[2]) or
					(Util.equ_2dpos(direction, {0, -1}) and cur[2] <= self_pos[2])) then
			print ("\t\tget_furthest_cell returning self boundary")
			return cur
		end

	end

end

function get_lead_cell(current_pos, target_pos, target_direction)
	local lookAheadTime = Util.distance_manhattan(current_pos, target_pos) / 2
	return get_furthest_cell(target_pos, target_direction, current_pos, math.ceil(lookAheadTime), false, false)
end

function is_actually_front(pos0, pos1, direction)
	local vec_dis = Util.add_2dpos(pos1, Util.mul_2dpos(pos0, -1))
	local relative = Util.dot_2dpos(Util.nom_2dpos(vec_dis), Util.nom_2dpos(direction))
	-- print("is_actually_front ", relative < -0.86)
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
		if v ~= except and v.pos.x ~= except.pos.x and v.pos.y ~= except.pos.y then
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
			print("Search dest set_: ", search_target[1], search_target[2])
			while true do

				local pos_obj = obj.pos
				-- if reached dest or dest is not passable, then choose another dest
				if pos_obj[1] == search_target[1] and pos_obj[2] == search_target[2] or
						session_current.map_obj:getcell(table.unpack(search_target)):ispassable() == false then
					search_target = find_search_pos(obj)
				end

				print("node_search searching")
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				set_all_unpassable(session_current.polices, obj)
				print("node_search pathfinding")
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(search_target)), cache)
				reset_unpassable(session_current.polices)
				print("node_search moving")
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end


				local table_cache = tyre.pfcache_to_table(cache)
				for i, v in ipairs(table_cache) do
					session_current.map_obj:getcell(v:unpack()):setinflfac(3.0)
				end

				print("node_search yielding")
				coroutine.yield(bt.state.RUNNING)
			end
			return bt.state.FAILURE
		end)
		node_search.evaluate = function () return (thief_found() == false) end

		local node_catch = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch mode...")

			while true do
				print("\tnode_catch catching...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				set_all_unpassable(session_current.polices, obj)
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(target)), cache)
				reset_unpassable(session_current.polices)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end


				local table_cache = tyre.pfcache_to_table(cache)
				for i, v in ipairs(table_cache) do
					session_current.map_obj:getcell(v:unpack()):setinflfac(3.0)
				end

				coroutine.yield(bt.state.RUNNING)
			end

			print("catch success")
			return bt.state.SUCCESS
		end)

		local node_catch_lead = btnode_create_coroutine(function (self, args)
			local obj = args.obj

			print("entering catch lead mode...")

			while true do
				print("\tnode_catch_lead catching lead...")
				local target = get_theif_pos(0)
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				local lead_cell = get_lead_cell(char.pos, target, Util.get_nearest_dir(session_current.thives[1]:get_move_direction_vec_smoothed()))
				set_all_unpassable(session_current.polices, obj)
				Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(lead_cell)), cache)
				reset_unpassable(session_current.polices)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end


				local table_cache = tyre.pfcache_to_table(cache)
				for i, v in ipairs(table_cache) do
					session_current.map_obj:getcell(v:unpack()):setinflfac(3.0)
				end

				coroutine.yield(bt.state.RUNNING)
			end

			print ("catch lead success")
			return bt.state.SUCCESS
		end)

		local node_creator = function (cell_callback, name)
			return btnode_create_coroutine(function (self, args)
				local obj = args.obj

				print("entering catch " .. name .. " mode...")

				while true do
					print("\tnode_catch " .. name .. " catching...")
					local target = get_theif_pos(0)
					local cache = Utility.Urd.Pathfinding.Pathfindingcache()
					set_all_unpassable(session_current.polices, obj)
					local target_cell = cell_callback(target, session_current.thives[1])
					Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(target_cell)), cache)
					reset_unpassable(session_current.polices)

					if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end

					local table_cache = tyre.pfcache_to_table(cache)
					for i, v in ipairs(table_cache) do
						session_current.map_obj:getcell(v:unpack()):setinflfac(3.0)
					end

					-- print('generating cache')
					-- local table_cache = tyre.pfcache_to_table(cache)
					-- print('cache generated')
					-- vhere.print_vectable(table_cache)

					coroutine.yield(bt.state.RUNNING)
				end

				print("catch " .. name .. " success")
			end)
		end

		local node_cache_behind = node_creator(function (targetpos, targetobj)
			local lead_cell = get_lead_cell(char.pos, targetpos, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()))
			print("catch behind lead ", lead_cell[1], lead_cell[2])
			local behind = get_furthest_cell(lead_cell, Util.mul_2dpos(Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()), -1), char.pos, 3)
			print("catch behind ", behind[1], behind[2])
			return behind
		end, "BEHIND")

		local node_catch_further = node_creator(function (targetpos, targetobj)
			local lead_cell = get_lead_cell(char.pos, targetpos, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()))
			print("catch further lead ", lead_cell[1], lead_cell[2])
			local further = get_furthest_cell(lead_cell, targetobj:get_move_direction_vec_smoothed(), char.pos, 2)
			print("catch further ", further[1], further[2])
			return further
		end, "FURTHER")

		local node_catch_last = node_creator(function (targetpos, targetobj)
			local lead_cell = get_lead_cell(char.pos, targetpos, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()))
			local furthest = get_furthest_cell(lead_cell, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()), char.pos, 2, false, false)
			print("catch last ", furthest[1], furthest[2])
			return furthest
		end, "lAST")

		local node_catch_last_random = node_creator(function (targetpos, targetobj)
			local lead_cell = get_lead_cell(char.pos, targetpos, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()))
			local furthest = get_furthest_cell(lead_cell, Util.get_nearest_dir(targetobj:get_move_direction_vec_smoothed()), char.pos, 2, false, false)
			local ret = get_random_cell(furthest, 2)
			print("catch last random ", ret[1], ret[2])
			return ret
		end, "lAST_RANDOM")

		print("initing brain...")

		local function set_state(state) return function() char._catch_state = state end end

		char.brain = bnd_repeat(512,
			bnd_sequential()
			:child(
				bdec_acomfront(node_search, set_state 'INITIAL')
			)
			:child(
				bnd_priority()
				:child(
					bdec_cond(bdec_acomfront(node_catch, set_state 'FRONT'), function () return
						is_actually_front(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vec_smoothed()) end,
						"CATCH_ACTUALLY_FRONT"))
				:child(
					bdec_cond(bdec_acomfront(node_catch, set_state 'NEAR'), function () return
						Util.distance(char.pos, session_current.thives[1].pos) <= 2 and count_of_state_pol_except(char, 'NEAR') < 1 end,
						"CATCH_NEAR"))
				:child(
					bdec_cond(bdec_acomfront(node_cache_behind, set_state 'BEHIND'), function () return
						char:is_behind(session_current.thives[1]) and is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vec_smoothed()) and count_of_state_pol_except(char, 'BEHIND') < 2 end,
						"CATCH_BEHIND"))
				:child(
					bdec_cond(bdec_acomfront(node_catch_further, set_state 'FUR'), function () return
						is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vec_smoothed()) and count_of_state_pol_except(char, 'FUR') < 2 end,
						"CATCHFUR"))
				:child(
					bdec_cond(bdec_acomfront(node_cache_behind, set_state 'SIDE'), function () return
						char:is_on_side_of(session_current.thives[1]) and count_of_state_pol_except(char, 'SIDE') < 1 end,
						"CATCHSIDE"))
				:child(
					bdec_acomfront(node_catch, set_state 'LAST')
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
		print("Catch mode: ", "*"..char._catch_state.."*")
		print("Is behind of thief: ", char:is_behind(session_current.thives[1]))
		print("Is on side of thief: ", char:is_on_side_of(session_current.thives[1]))
		print("Is on the exact side of thief: ", is_actually_side(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vector_single()))
		print("Is in front of thief: ", char:is_in_front_of(session_current.thives[1]))
		print("Is on the exact front of thief: ", is_actually_front(char.pos, session_current.thives[1].pos, session_current.thives[1]:get_move_direction_vec_smoothed()))
		print('')

		statuses = statuses .. char._catch_state
		statuses = statuses .. '\n'

	end

	local t = session_current.thives[1]:get_move_direction_vector_single()
	print("Thief 0 move vector: ", t[1], t[2])

	local t_smoothed = session_current.thives[1]:get_move_direction_vec_smoothed()
	print("Thief 0 move vector (smoothed): ", t_smoothed[1], t_smoothed[2])
end
end
