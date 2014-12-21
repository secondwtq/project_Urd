dofile('lunalogger.lua')

dofile('lunabehavior.lua')

function we_are_thieves()
	return Env.INST_INIT == 'THI' end

function police_found_any()
	for id, police in ipairs(session_current.polices) do
		if police.found then return true end
	end
	return false
end

function get_polices_onsight()

	local ret = { }

	for i, police in ipairs(session_current.polices) do
		if police.onsight then
			print('police: ', police.id, 'onsight')
			table.insert(ret, police)
		end
	end

	return ret
end

function urdthi_init()
if we_are_thieves() then
	for i, char in ipairs(session_current.thives) do

		char._catch_state = 'NONE'

		local node_search_creator = function (search_foo, once)
			return btnode_create_coroutine(function (self, args)
				if once == nil then once = true end

				local obj = args.obj
				print("Searching for target...")
				local search_target = search_foo(obj)
				print("Search dest set: ", search_target[1], search_target[2])
				while true do

					local pos_obj = obj.pos
					-- if reached dest or dest is not passable, then choose another dest
					if ((not once) and pos_obj[1] == search_target[1] and pos_obj[2] == search_target[2]) or
							session_current.map_obj:getcell(table.unpack(search_target)):ispassable() == false then
						search_target = search_foo(obj)
						print('resetting dest set: ', search_target[1], search_target[2])
					elseif pos_obj[1] == search_target[1] and pos_obj[2] == search_target[2] then
						return bt.state.SUCCESS
					end

					print("node_search searching")
					local cache = Utility.Urd.Pathfinding.Pathfindingcache()
					set_all_unpassable(session_current.thives, obj)
					print("node_search pathfinding")
					Utility.Urd.Pathfinding.find_8(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(search_target)), cache)
					reset_unpassable(session_current.thives)
					if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end

					local table_cache = tyre.pfcache_to_table(cache)
					for i, v in ipairs(table_cache) do
						session_current.map_obj:getcell(v:unpack()):setinflfac(4.0)
					end

					print("node_search yielding")
					coroutine.yield(bt.state.RUNNING)
				end
				return bt.state.FAILURE
			end)
		end

		local node_search = node_search_creator(find_search_pos)
		node_search.evaluate = function () return (police_found_any() == false) end

		local node_search_random = node_search_creator(find_search_pos_random, false)
		node_search_random.evaluate = function () return police_found_any() == false end

		local node_influ_move = btnode_create_coroutine(function (self, args)
			local obj = args.obj
			print('entering influmove mode...')

			while true do
				obj.influ_map:clear_map()
				obj.influ_map:clear_influnode()

				local police_onsight = get_polices_onsight()
				print(#police_onsight, "polices onsight")

				for i, police in ipairs(police_onsight) do
					obj.influ_map:add_node(vhere.vector2d(table.unpack(police.pos)), vhere.vector2d(table.unpack(obj.pos)))
				end

				local dir_move = { {0, 1}, {1, 0}, {0, -1}, {-1, 0} }
				local pos_move = { }

				for i, dir in ipairs(dir_move) do
					pos_move[i] = vhere.vector2d(table.unpack(dir)) + vhere.vector2d(table.unpack(obj.pos))
				end

				for i, pos in ipairs(pos_move) do print (pos.x, pos.y, obj.influ_map:get_value(pos)) end

				local pos_move_filtered = { }
				for i, pos in ipairs(pos_move) do
					if session_current.map_obj:getcell(pos:unpack()):ispassable() then
						table.insert(pos_move_filtered, {i, pos})
					end
				end

				print('filtered result:')
				for i, pos in ipairs(pos_move_filtered) do print (pos[2].x, pos[2].y, obj.influ_map:get_value(pos[2])) end

				local pos_move_min = obj.influ_map:get_value(pos_move_filtered[1][2])
				local pos_move_idx = pos_move_filtered[1][1]
				print("initial move idx:", pos_move_idx)
				for i, pos in ipairs(pos_move_filtered) do
					if obj.influ_map:get_value(pos[2]) < pos_move_min then
						pos_move_idx = pos[1]
						pos_move_min = obj.influ_map:get_value(pos[2])
					end
				end

				print("move idx:", pos_move_idx, "direction: ", table.unpack(dir_move[pos_move_idx]))
				obj:move(directions.from_vec_to_dir(dir_move[pos_move_idx]))

				coroutine.yield(bt.state.RUNNING)
			end

			return bt.state.SUCCESS
		end)

		print('initing influmap...')
		char.influ_map = influ.influmap:new()
		char.influ_map:create_map(session_current.map_obj.width, session_current.map_obj.height)
		char.influ_map:clear_map()
		char.influ_map:clear_influnode()

		print("initing brain...")

		local function set_state(state) return function() char._catch_state = state end end

		char.brain = bnd_repeat(512,
			bnd_sequential()
			:child(
				bdec_acomfront(node_search, set_state 'INITIAL')
			)
			:child(
				bdec_acomfront(node_search_random, set_state 'RANDOM_SEARCH')
			)
			:child(
				bnd_priority()
				:child(
					bdec_acomfront(node_influ_move, set_state 'ESCAPING')
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

function urdthi_tick()
if we_are_thieves() then
	for i, char in ipairs(session_current.thives) do

		if char.brain_activated then
			print("exectuing brain...")
			local status = char.brain:execute({obj = char})
			if status ~= bt.state.RUNNING then
				char.brain_activated = false
			end
		end

		print('')
		print('')

		statuses = statuses .. char._catch_state
		statuses = statuses .. '\n'

	end

end
end
