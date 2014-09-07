function we_are_police()
	return Env.INST_INIT == 'POL' end

dofile('lunabehavior.lua')

function thief_found()
	return session_current.thives[1].found end

function urdpol_init()
if we_are_police() then
	for i, char in ipairs(session_current.polices) do
		print("initing brain...")
		char.brain = btnode_create_sequential()

		local node_search = btnode_coroutine:new()
		node_search.co_execute = function (self, args)
			local obj = args.obj
			-- print(search_target[1], search_target[2])

			while true do
				local search_target = { session_current.map_obj.width-obj.pos[1]-1, session_current.map_obj.height-obj.pos[2]-1 }
				print(search_target[1], search_target[2])
				local cache = Utility.Urd.Pathfinding.Pathfindingcache()
				Utility.Urd.Pathfinding.find(obj:getcell(session_current.map_obj), session_current.map_obj:getcell(table.unpack(search_target)), cache)
				if not cache:ended() then obj:move(directions.get_direction(cache:getCur():getpos(), cache:next():getpos())) end
				coroutine.yield(bt.state.RUNNING)
			end

			coroutine.yield(bt.state.SUCCESS)
		end

		char.brain:add_child(
			btnode_create_sequential()
				:add_child(btnode_create_condition(thief_found, false))
				:add_child(node_search)
			)

		char.brain:init()
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