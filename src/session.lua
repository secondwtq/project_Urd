session = { }

object = require 'object'
Util = require 'ubtutil'
LCT = require 'lunacolort'
directions = require 'directions'
Env = require 'Environment'

Entity = object.object:new({

	id = 0,

	pos = { 0, 0 },

	mov_id = 'D',

	found = false,

	onsight = false,

	previous_position_single = nil,

	previous_move_vector = nil,

	move_vectors = { },

	_get_move_direction_vector_single = function (self)
		if self.previous_position_single == nil then
			self.previous_position_single = { self.pos[1], self.pos[2] }
		end

		local move_offset_x = self.pos[1] - self.previous_position_single[1]
		local move_offset_y = self.pos[2] - self.previous_position_single[2]

		if move_offset_x == 0 and move_offset_y == 0 then
			return { 0, 0 }
		end

		if move_offset_x >= 0 and move_offset_y >= 0 then
			if move_offset_x > move_offset_y then return { 1, 0 }
			else return { 0, 1 } end
		end
		if move_offset_x <= 0 and move_offset_y >= 0 then
			if (-move_offset_x) > move_offset_y then return { -1, 0 }
			else return { 0, 1 } end
		end
		if move_offset_x >= 0 and move_offset_y <= 0 then
			if move_offset_x > (-move_offset_y) then return { 1, 0 }
			else return { 0, -1 } end
		end
		if move_offset_x <= 0 and move_offset_y <= 0 then
			if (-move_offset_x) > (-move_offset_y) then return { -1, 0 }
			else return { 0, -1 } end
		end
	end,

	get_move_direction_vector_single = function (self)
		local ret = self:_get_move_direction_vector_single()

		if directions.from_vec_to_dir(ret) == directions.Directions.Still then
			if self.previous_move_vector == nil then
				self.previous_move_vector = ret
				return ret
			else
				return self.previous_move_vector
			end
		else
			self.previous_move_vector = ret
			return ret
		end
	end,

	get_move_direction_vec_smoothed = function (self, max_step)
		if max_step == nil then max_step = 3 end

		local vecs = { }
		local last_vec = self:get_move_direction_vector_single()

		for i = #(self.move_vectors), #(self.move_vectors)-max_step+1, -1 do
			if i > 0 then table.insert(vecs, self.move_vectors[i])
			else table.insert(vecs, last_vec) end
		end

		-- for i, v in ipairs(vecs) do
		-- 	io.write("<"..tostring(v[1])..", "..tostring(v[2])..">, ")
		-- end
		-- print('')

		local ret = { 0, 0 }
		for i, v in ipairs(vecs) do
			ret = Util.add_2dpos(ret, v)
		end

		return Util.nom_2dpos(Util.mul_2dpos(ret, 1.0/max_step))
	end,

	is_in_front_of = function (self, other)
		local pos_self = self:getpos()
		local pos_other = other:getpos()

		local pos_offset = Util.add_2dpos(Util.mul_2dpos(pos_self, -1), pos_other)
		local dir_offset = directions.get_primary_direction(table.unpack(pos_offset))

		local dir_self = directions.from_vec_to_dir(self:get_move_direction_vector_single())
		local dir_other = directions.from_vec_to_dir(other:get_move_direction_vector_single())

		if directions.abs_to_rel(dir_offset, dir_other) == directions.DirectionRelative.Opposite then
			return true
		else return false end
	end,

	is_behind = function (self, other)
		local pos_self = self:getpos()
		local pos_other = other:getpos()

		local dir_other = directions.from_vec_to_dir(other:get_move_direction_vector_single())

		if dir_other == directions.Directions.Left then
			if pos_self[1] > pos_other[1] then return true end
		end
		if dir_other == directions.Directions.Right then
			if pos_self[1] < pos_other[1] then return true end
		end
		if dir_other == directions.Directions.Up then
			if pos_self[2] > pos_other[2] then return true end
		end
		if dir_other == directions.Directions.Down then
			if pos_self[2] < pos_other[2] then return true end
		end

		return false
	end,

	is_on_side_of = function (self, other)
		local pos_self = self:getpos()
		local pos_other = other:getpos()

		local pos_offset = Util.add_2dpos(Util.mul_2dpos(pos_self, -1), pos_other)
		local dir_offset = directions.get_primary_direction(table.unpack(pos_offset))

		local dir_other = directions.from_vec_to_dir(other:get_move_direction_vector_single())

		local rel = directions.abs_to_rel(dir_offset, dir_other)

		if rel == directions.DirectionRelative.Left or rel == directions.DirectionRelative.Right then
			return true
		else return false end
	end,

	move = function (self, dir) self.mov_id = dir end,

	getpos = function (self) return self.pos end,

	setpos = function (self, x, y) self.pos = { x, y } end,

	getobjtype = function (self) return 'undefined' end,

	getcell = function (self, _mapobj) return _mapobj:getcell(unpack(self.pos)) end,

	debug_data = function (self) return string.format('Entity: %s, id=%d, x=%d, y=%d\n', self:getobjtype(), self.id, unpack(self.pos)) end
	})

PoliceObject = Entity:new({

	getobjtype = function (self) return 'POL' end,

	})

ThiefObject = Entity:new({

	getobjtype = function (self) return 'THI' end,

	})

session.PoliceObject, session.ThiefObject = PoliceObject, ThiefObject

session.SessionObject = object.object:new({

	map_obj = nil,

	num_pol = 0,

	num_thi = 0,

	sight_pol = 0,

	sight_thi = 0,

	polices = { },

	thives = { },

	is_cell_passable = function(self, obj, cell)
		local ret = self.map_obj:getcell(table.unpack(cell)):passable()
		if ret == false then return false end

		local obses = nil
		if Util.we_are_police() then obses = self.polices
		else obses = self.thives end

		for i, v in ipairs(obses) do
			if obj ~= v then
				if Util.equ_2dpos(cell, v:getpos()) then return false end
			end
		end

		return true
	end,
	
	before_update = function (self)
		Util.findin(self.polices, function (o) o.mov_id = 'T' end)
		Util.findin(self.thives, function (o) o.mov_id = 'T' end)
		self.map_obj:clear_on_sight()
		self.map_obj:clear_on_path()
	end,

	init_entities = function (self, num_pol, num_thi, type_self)
		self.polices, self.thives = { }, { }
		self.num_pol, self.num_thi = num_pol, num_thi

		for i = 1, num_pol do
			local t = PoliceObject:new()
			t.id = i-1
			t.move_vectors = { }
			table.insert(self.polices, t)
		end
		for i = 1, num_thi do 
			local t = ThiefObject:new()
			t.id = i-1
			t.move_vectors = { }
			table.insert(self.thives, t)
		end
	end,

	debug_data = function (self)
		local r = LCT.c.RED .. 'Session Debug Data\n' .. LCT.c.RESET
		if self.map_obj ~= nil then r = r .. string.format('Map width: %d, height: %d\n', self.map_obj.width, self.map_obj.height)
		else r = r .. "Map data not inited.\n" end
		r = r .. string.format('Num of polices: %d, thives: %d\n', self.num_pol, self.num_thi)
		.. string.format('Sight of polices: %d, thives: %d\n', self.sight_pol, self.sight_thi)
		.. LCT.c.YELLOW .. 'Detailed data of entities:\n' .. LCT.c.RESET

		Util.findin(self.polices, function (o) r = r .. o:debug_data() end)
		Util.findin(self.thives, function (o) r = r .. o:debug_data() end)
		return r
	end,

	pass_mov = function (self, ntick, type_self)
		local entities = nil
		if type_self == 'POL' then entities = self.polices else entities = self.thives end
		local t = ''
		Util.findin(entities, function (o) t = t .. string.format('%d,%s;', o.id, o.mov_id) end)

		return string.format('MOV[%d](%s)', ntick, t)
	end

	})

return session
